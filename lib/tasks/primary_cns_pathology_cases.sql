DROP TABLE IF EXISTS cancer_abstractions;

CREATE TEMPORARY TABLE cancer_abstractions
(
 id                                           BIGINT        NOT NULL,
 note_id                                      BIGINT        NOT NULL,
 stable_identifier_path                       varchar(255)  NULL,
 stable_identifier_value                      varchar(255)  NULL,
 subject_id                                   BIGINT        NOT NULL ,
 has_idh1_status                              varchar(255)  NULL,
 has_idh2_status                              varchar(255)  NULL,
 has_1p_status                                varchar(255)  NULL,
 has_19q_status                               varchar(255)  NULL,
 has_10q_PTEN_status                          varchar(255)  NULL,
 has_mgmt_status                              varchar(255)  NULL,
 has_ki67                                     varchar(255)  NULL,
 has_p53                                      varchar(255)  NULL,
 has_cancer_integrated_histology              varchar(255)  NULL,
 has_cancer_integrated_histology_suggestions  varchar(255)  NULL,
 has_surgery_date                             varchar(255)  NULL,
 about_id                                     BIGINT        NOT NULL
);

INSERT INTO cancer_abstractions (
   id
 , note_id
 , stable_identifier_path
 , stable_identifier_value
 , subject_id
 , has_idh1_status
 , has_idh2_status
 , has_1p_status
 , has_19q_status
 , has_10q_PTEN_status
 , has_mgmt_status
 , has_ki67
 , has_p53
 , has_cancer_integrated_histology
 , has_cancer_integrated_histology_suggestions
 , has_surgery_date
 , about_id
)
SELECT note_stable_identifier.id
     , note_stable_identifier_full.note_id
     , note_stable_identifier.stable_identifier_path
     , note_stable_identifier.stable_identifier_value
     , pivoted_abstractions.subject_id
     , pivoted_abstractions.has_idh1_status
     , pivoted_abstractions.has_idh2_status
     , pivoted_abstractions.has_1p_status
     , pivoted_abstractions.has_19q_status
     , pivoted_abstractions.has_10q_PTEN_status
     , pivoted_abstractions.has_mgmt_status
     , pivoted_abstractions.has_ki67
     , pivoted_abstractions.has_p53
     , pivoted_abstractions.has_cancer_integrated_histology
     , array_to_string(array(
         SELECT DISTINCT asg2.suggested_value
         FROM abstractor_abstractions aa2 JOIN abstractor_suggestions asg2 on aa2.id = asg2.abstractor_abstraction_id
                                          JOIN abstractor_subjects asb2 ON aa2.abstractor_subject_id = asb2.id
                                          JOIN abstractor_abstraction_schemas aas2 ON asb2.abstractor_abstraction_schema_id = aas2.id
         WHERE aa2.about_id = pivoted_abstractions.about_id
         AND aas2.predicate = 'has_cancer_integrated_histology'
         AND asg2.suggested_value IS NOT NULL
       ), ', ') AS has_cancer_integrated_histology_suggestions
     , pivoted_abstractions.has_surgery_date
     , pivoted_abstractions.about_id
FROM note_stable_identifier JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     LEFT JOIN (SELECT note_stable_identifier.id AS subject_id,
                       Max(CASE
                             WHEN data.predicate = 'has_idh1_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_idh1_status,
                       Max(CASE
                             WHEN data.predicate = 'has_idh2_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_idh2_status,
                       Max(CASE
                             WHEN data.predicate = 'has_1p_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_1p_status,
                       Max(CASE
                             WHEN data.predicate = 'has_19q_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_19q_status,
                       Max(CASE
                             WHEN data.predicate = 'has_10q_PTEN_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_10q_PTEN_status,
                       Max(CASE
                             WHEN data.predicate = 'has_mgmt_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_mgmt_status,
                       Max(CASE
                             WHEN data.predicate = 'has_ki67' THEN data.value
                             ELSE NULL
                           END)                  AS has_ki67,
                       Max(CASE
                             WHEN data.predicate = 'has_p53' THEN data.value
                             ELSE NULL
                           END)                  AS has_p53,
                       Max(CASE
                             WHEN data.predicate = 'has_cancer_integrated_histology' THEN data.value
                             ELSE NULL
                           END)                  AS has_cancer_integrated_histology,
                       Max(CASE
                             WHEN data.predicate = 'has_surgery_date' THEN data.value
                             ELSE NULL
                           END)                  AS has_surgery_date,
                      about_id
                FROM   (SELECT aas.predicate,
                               aas.id AS abstractor_abstraction_schema_id,
                               asb.subject_type,
                               aa.about_id,
                               CASE
                                 WHEN aa.value IS NOT NULL
                                      AND aa.value != '' THEN aa.value
                                 WHEN aa.unknown = true THEN 'unknown'
                                 WHEN aa.not_applicable = true THEN
                                 'not applicable'
                               END    AS value
                        FROM   abstractor_abstractions aa
                               JOIN abstractor_subjects asb
                                 ON aa.abstractor_subject_id = asb.id
                               JOIN abstractor_abstraction_schemas aas
                                 ON asb.abstractor_abstraction_schema_id =
                                    aas.id
                        WHERE  asb.subject_type = 'NoteStableIdentifier'
                               AND asb.namespace_type =
                                   'Abstractor::AbstractorNamespace'
                               AND asb.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
                               AND aa.deleted_at IS NULL
                               AND NOT
                       EXISTS (SELECT 1
                               FROM   abstractor_abstraction_group_members
                                      aagm
                               WHERE  aa.id = aagm.abstractor_abstraction_id))
                       data
                       JOIN note_stable_identifier
                         ON data.about_id = note_stable_identifier.id
                GROUP  BY note_stable_identifier.id, data.about_id) pivoted_abstractions
            ON pivoted_abstractions.subject_id = note_stable_identifier.id
WHERE  ( EXISTS (SELECT 1
               FROM   abstractor_abstractions aa
                      JOIN abstractor_subjects sub
                        ON aa.abstractor_subject_id = sub.id
                           AND sub.namespace_type =
                               'Abstractor::AbstractorNamespace'
                           AND sub.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
               WHERE  aa.deleted_at IS NULL
                      AND aa.about_type = 'NoteStableIdentifier'
                      AND note_stable_identifier.id = aa.about_id)
       -- AND NOT EXISTS (SELECT 1
       --                 FROM   abstractor_abstractions aa
       --                        JOIN abstractor_subjects sub
       --                          ON aa.abstractor_subject_id = sub.id
       --                             AND sub.namespace_type =
       --                                 'Abstractor::AbstractorNamespace'
       --                             AND sub.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
       --                 WHERE  aa.deleted_at IS NULL
       --                        AND aa.about_type = 'NoteStableIdentifier'
       --                        AND note_stable_identifier.id = aa.about_id
       --                        AND COALESCE(aa.value, '') = ''
       --                        AND COALESCE(aa.unknown, false) != true
       --                        AND COALESCE(aa.not_applicable, false) != true)
     )
;

DROP TABLE IF EXISTS cancer_diagnosis_abstractions;

CREATE TEMPORARY TABLE cancer_diagnosis_abstractions
(
  id                                       BIGINT        NOT NULL,
  note_id                                  BIGINT        NOT NULL,
  stable_identifier_path                   varchar(255)  NULL,
  stable_identifier_value                  varchar(255)  NULL,
  subject_id                               BIGINT        NOT NULL,
  diagnosis_type                           varchar(255)  NULL,
  has_cancer_histology                     varchar(255)  NULL,
  has_cancer_histology_suggestions         text NULL,
  has_cancer_site                          varchar(255)  NULL,
  has_cancer_site_suggestions              text NULL,
  has_cancer_site_laterality               varchar(255)  NULL,
  has_cancer_who_grade                     varchar(255)  NULL,
  has_metastatic_cancer_primary_site       varchar(255)  NULL,
  has_cancer_recurrence_status             varchar(255)  NULL,
  abstractor_namespace_name                varchar(255)  NULL,
  about_id                                 BIGINT        NOT NULL
);

INSERT INTO cancer_diagnosis_abstractions (
   id
 , note_id
 , stable_identifier_path
 , stable_identifier_value
 , subject_id
 , diagnosis_type
 , has_cancer_histology
 , has_cancer_histology_suggestions
 , has_cancer_site
 , has_cancer_site_suggestions
 , has_cancer_site_laterality
 , has_cancer_who_grade
 , has_cancer_recurrence_status
 , abstractor_namespace_name
 , about_id
)
SELECT note_stable_identifier.id
     , note_stable_identifier_full.note_id
     , note_stable_identifier.stable_identifier_path
     , note_stable_identifier.stable_identifier_value
     , pivoted_abstractions.subject_id
     , 'Primary Cancer' AS diagnosis_type
     , pivoted_abstractions.has_cancer_histology
     , array_to_string(array(
         SELECT DISTINCT asg2.suggested_value
         FROM abstractor_abstractions aa2 JOIN abstractor_suggestions asg2 on aa2.id = asg2.abstractor_abstraction_id
                                          JOIN abstractor_subjects asb2 ON aa2.abstractor_subject_id = asb2.id
                                          JOIN abstractor_abstraction_schemas aas2 ON asb2.abstractor_abstraction_schema_id = aas2.id
                                          JOIN abstractor_abstraction_group_members aagm ON aa2.id = aagm.abstractor_abstraction_id
                                          JOIN abstractor_abstraction_groups aag ON aagm.abstractor_abstraction_group_id = aag.id
                                          JOIN abstractor_subject_groups asg ON aag.abstractor_subject_group_id = asg.id
         WHERE aa2.about_id = pivoted_abstractions.about_id
         AND aas2.predicate = 'has_cancer_histology'
         AND asg2.suggested_value IS NOT NULL
         AND asg.name = 'Primary Cancer'
       ), ', ') AS has_cancer_histology_suggestions
     , pivoted_abstractions.has_cancer_site
     , array_to_string(array(
         SELECT DISTINCT asg2.suggested_value
         FROM abstractor_abstractions aa2 JOIN abstractor_suggestions asg2 on aa2.id = asg2.abstractor_abstraction_id
                                          JOIN abstractor_subjects asb2 ON aa2.abstractor_subject_id = asb2.id
                                          JOIN abstractor_abstraction_schemas aas2 ON asb2.abstractor_abstraction_schema_id = aas2.id
                                          JOIN abstractor_abstraction_group_members aagm ON aa2.id = aagm.abstractor_abstraction_id
                                          JOIN abstractor_abstraction_groups aag ON aagm.abstractor_abstraction_group_id = aag.id
                                          JOIN abstractor_subject_groups asg ON aag.abstractor_subject_group_id = asg.id
         WHERE aa2.about_id = pivoted_abstractions.about_id
         AND aas2.predicate = 'has_cancer_site'
         AND asg2.suggested_value IS NOT NULL
         AND asg.name = 'Primary Cancer'
       ), ', ') AS has_cancer_site_suggestions
     , pivoted_abstractions.has_cancer_site_laterality
     , pivoted_abstractions.has_cancer_who_grade
     , pivoted_abstractions.has_cancer_recurrence_status
     , pivoted_abstractions.abstractor_namespace_name
     , pivoted_abstractions.about_id
FROM note_stable_identifier JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
      JOIN (SELECT note_stable_identifier.id AS subject_id,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_histology' THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_histology,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_site' THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_site,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_site_laterality'
                       THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_site_laterality,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_who_grade' THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_who_grade,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_recurrence_status'
                       THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_recurrence_status,
                       abstractor_abstraction_group_id,
                   abstractor_namespace_name,
                   about_id
            FROM   (SELECT aas.predicate,
                           aas.id AS abstraction_schema_id,
                           asb.subject_type,
                           aa.about_id,
                           CASE
                             WHEN aa.value IS NOT NULL
                                  AND aa.value != '' THEN aa.value
                             WHEN aa.unknown = true THEN 'unknown'
                             WHEN aa.not_applicable = true THEN
                             'not applicable'
                           END    AS value,
                           aag.id AS abstractor_abstraction_group_id,
                           an.name AS abstractor_namespace_name
                    FROM   abstractor_abstractions aa
                           JOIN abstractor_subjects asb
                             ON aa.abstractor_subject_id = asb.id
                           JOIN abstractor_abstraction_schemas aas
                             ON asb.abstractor_abstraction_schema_id = aas.id
                           JOIN abstractor_abstraction_group_members aagm
                             ON aa.id = aagm.abstractor_abstraction_id
                           JOIN abstractor_abstraction_groups aag
                             ON aagm.abstractor_abstraction_group_id = aag.id
                           JOIN abstractor_namespaces an ON asb.namespace_id = an.id AND asb.namespace_type = 'Abstractor::AbstractorNamespace'
                           JOIN abstractor_subject_groups asg ON aag.abstractor_subject_group_id = asg.id AND asg.name = 'Primary Cancer'
                    WHERE  asb.subject_type = 'NoteStableIdentifier'
                           AND asb.namespace_type =
                               'Abstractor::AbstractorNamespace'
                           AND asb.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
                           AND aa.deleted_at IS NULL) data
                   JOIN note_stable_identifier
                     ON data.about_id = note_stable_identifier.id
            GROUP  BY note_stable_identifier.id, abstractor_abstraction_group_id, abstractor_namespace_name, about_id) pivoted_abstractions
        ON pivoted_abstractions.subject_id = note_stable_identifier.id
WHERE  ( EXISTS (SELECT 1
                FROM   abstractor_abstractions aa
                       JOIN abstractor_subjects sub
                         ON aa.abstractor_subject_id = sub.id
                            AND sub.namespace_type =
                                'Abstractor::AbstractorNamespace'
                            AND sub.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
                WHERE  aa.deleted_at IS NULL
                       AND aa.about_type = 'NoteStableIdentifier'
                       AND note_stable_identifier.id = aa.about_id)

        )
AND pivoted_abstractions.abstractor_namespace_name IN(
 'Outside Surgical Pathology'
,'Surgical Pathology'
);


INSERT INTO cancer_diagnosis_abstractions (
   id
 , note_id
 , stable_identifier_path
 , stable_identifier_value
 , subject_id
 , diagnosis_type
 , has_cancer_histology
 , has_cancer_histology_suggestions
 , has_cancer_site
 , has_cancer_site_suggestions
 , has_cancer_site_laterality
 , has_metastatic_cancer_primary_site
 , has_cancer_recurrence_status
 , abstractor_namespace_name
 , about_id
)
SELECT note_stable_identifier.id
     , note_stable_identifier_full.note_id
     , note_stable_identifier.stable_identifier_path
     , note_stable_identifier.stable_identifier_value
     , pivoted_abstractions.subject_id
     , 'Metastatic Cancer' AS diagnosis_type
     , pivoted_abstractions.has_metastatic_cancer_histology
     , array_to_string(array(
         SELECT DISTINCT asg2.suggested_value
         FROM abstractor_abstractions aa2 JOIN abstractor_suggestions asg2 on aa2.id = asg2.abstractor_abstraction_id
                                          JOIN abstractor_subjects asb2 ON aa2.abstractor_subject_id = asb2.id
                                          JOIN abstractor_abstraction_schemas aas2 ON asb2.abstractor_abstraction_schema_id = aas2.id
                                          JOIN abstractor_abstraction_group_members aagm ON aa2.id = aagm.abstractor_abstraction_id
                                          JOIN abstractor_abstraction_groups aag ON aagm.abstractor_abstraction_group_id = aag.id
                                          JOIN abstractor_subject_groups asg ON aag.abstractor_subject_group_id = asg.id
         WHERE aa2.about_id = pivoted_abstractions.about_id
         AND aas2.predicate = 'has_metastatic_cancer_histology'
         AND asg2.suggested_value IS NOT NULL
         AND asg.name = 'Metastatic Cancer'
       ), ', ') AS has_metastatic_cancer_histology_suggestions
     , pivoted_abstractions.has_cancer_site
     , array_to_string(array(
         SELECT DISTINCT asg2.suggested_value
         FROM abstractor_abstractions aa2 JOIN abstractor_suggestions asg2 on aa2.id = asg2.abstractor_abstraction_id
                                          JOIN abstractor_subjects asb2 ON aa2.abstractor_subject_id = asb2.id
                                          JOIN abstractor_abstraction_schemas aas2 ON asb2.abstractor_abstraction_schema_id = aas2.id
                                          JOIN abstractor_abstraction_group_members aagm ON aa2.id = aagm.abstractor_abstraction_id
                                          JOIN abstractor_abstraction_groups aag ON aagm.abstractor_abstraction_group_id = aag.id
                                          JOIN abstractor_subject_groups asg ON aag.abstractor_subject_group_id = asg.id
         WHERE aa2.about_id = pivoted_abstractions.about_id
         AND aas2.predicate = 'has_cancer_site'
         AND asg2.suggested_value IS NOT NULL
         AND asg.name = 'Metastatic Cancer'
       ), ', ') AS has_cancer_site_suggestions
     , pivoted_abstractions.has_cancer_site_laterality
     , pivoted_abstractions.has_metastatic_cancer_primary_site
     , pivoted_abstractions.has_cancer_recurrence_status
     , pivoted_abstractions.abstractor_namespace_name
     , pivoted_abstractions.about_id
FROM note_stable_identifier JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
      JOIN (SELECT note_stable_identifier.id AS subject_id,
                   Max(CASE
                         WHEN data.predicate = 'has_metastatic_cancer_histology' THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_metastatic_cancer_histology,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_site' THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_site,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_site_laterality'
                       THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_site_laterality,
                   Max(CASE
                         WHEN data.predicate = 'has_metastatic_cancer_primary_site' THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_metastatic_cancer_primary_site,
                   Max(CASE
                         WHEN data.predicate = 'has_cancer_recurrence_status'
                       THEN
                         data.value
                         ELSE NULL
                       END)                  AS has_cancer_recurrence_status,
                       abstractor_abstraction_group_id,
                   abstractor_namespace_name,
                   about_id
            FROM   (SELECT aas.predicate,
                           aas.id AS abstraction_schema_id,
                           asb.subject_type,
                           aa.about_id,
                           CASE
                             WHEN aa.value IS NOT NULL
                                  AND aa.value != '' THEN aa.value
                             WHEN aa.unknown = true THEN 'unknown'
                             WHEN aa.not_applicable = true THEN
                             'not applicable'
                           END    AS value,
                           aag.id AS abstractor_abstraction_group_id,
                           an.name AS abstractor_namespace_name
                    FROM   abstractor_abstractions aa
                           JOIN abstractor_subjects asb
                             ON aa.abstractor_subject_id = asb.id
                           JOIN abstractor_abstraction_schemas aas
                             ON asb.abstractor_abstraction_schema_id = aas.id
                           JOIN abstractor_abstraction_group_members aagm
                             ON aa.id = aagm.abstractor_abstraction_id
                           JOIN abstractor_abstraction_groups aag
                             ON aagm.abstractor_abstraction_group_id = aag.id
                           JOIN abstractor_namespaces an ON asb.namespace_id = an.id AND asb.namespace_type = 'Abstractor::AbstractorNamespace'
                           JOIN abstractor_subject_groups asg ON aag.abstractor_subject_group_id = asg.id AND asg.name = 'Metastatic Cancer'
                    WHERE  asb.subject_type = 'NoteStableIdentifier'
                           AND asb.namespace_type =
                               'Abstractor::AbstractorNamespace'
                           AND asb.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
                           -- AND aag.abstractor_subject_group_id = (SELECT id FROM abstractor_subject_groups WHERE name = 'Metastatic Cancer')
                           AND aa.deleted_at IS NULL) data
                   JOIN note_stable_identifier
                     ON data.about_id = note_stable_identifier.id
            GROUP  BY note_stable_identifier.id, abstractor_abstraction_group_id, abstractor_namespace_name, about_id) pivoted_abstractions
        ON pivoted_abstractions.subject_id = note_stable_identifier.id
WHERE  ( EXISTS (SELECT 1
                FROM   abstractor_abstractions aa
                       JOIN abstractor_subjects sub
                         ON aa.abstractor_subject_id = sub.id
                            AND sub.namespace_type =
                                'Abstractor::AbstractorNamespace'
                            AND sub.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Surgical Pathology', 'Outside Surgical Pathology'))
                WHERE  aa.deleted_at IS NULL
                       AND aa.about_type = 'NoteStableIdentifier'
                       AND note_stable_identifier.id = aa.about_id)
        )
AND pivoted_abstractions.abstractor_namespace_name IN(
  'Surgical Pathology'
, 'Outside Surgical Pathology'
);

--inside
INSERT INTO primary_cns_pathology_cases
(
  abstractor_namespace_name
, west_mrn
, note_stable_identifier_path
, note_stable_identifier_value_1
, note_stable_identifier_value_2
, note_id
, pathology_stable_identifier_path
, pathology_stable_identifier_value_1
, pathology_procedure_date
, pathology_provider_name
, pathology_procedure_source_value
, pathology_concept_name
, surgery_stable_identifier_path
, surgery_stable_identifier_value_1
, surgery_procedure_date
, surgery_provider_name
, surgery_procedure_source_value
, surgery_concept_name
, diagnosis_type
, has_cancer_histology
, has_cancer_histology_suggestions
, integrated_mention
, has_cancer_integrated_histology
, has_cancer_integrated_histology_suggestions
, has_cancer_site
, has_cancer_site_suggestions
, has_cancer_site_laterality
, has_cancer_who_grade
, has_metastatic_cancer_primary_site
, has_cancer_recurrence_status
, has_idh1_status
, has_idh2_status
, has_1p_status
, has_19q_status
, has_10q_pten_status
, has_mgmt_status
, has_ki67
, has_p53
, has_surgery_date
)
SELECT
        cancer_diagnosis_abstractions.abstractor_namespace_name
      , data.person_source_value                          AS west_mrn
      , data.note_stable_identifier_path
      , data.note_stable_identifier_value_1
      , data.note_stable_identifier_value_2
      , data.note_id
      , data.pathology_stable_identifier_path
      , data.pathology_stable_identifier_value_1
      , data.pathology_procedure_date
      , data.pathology_provider_name
      , data.pathology_procedure_source_value
      , data.pathology_concept_name
      , data.surgery_stable_identifier_path
      , data.surgery_stable_identifier_value_1
      , data.surgery_procedure_date
      , data.surgery_provider_name
      , data.surgery_procedure_source_value
      , data.surgery_concept_name
      , cancer_diagnosis_abstractions.diagnosis_type
      , cancer_diagnosis_abstractions.has_cancer_histology
      , cancer_diagnosis_abstractions.has_cancer_histology_suggestions
      , case when data.note_text like '%integrated histology%' or data.note_text like '%integrated-histology%' or data.note_text like '%integrated diagnosis%' or data.note_text like '%integrated-diagnosis%' then 'yes' else 'no' end as integrated_mention
      , cancer_abstractions.has_cancer_integrated_histology
      , cancer_abstractions.has_cancer_integrated_histology_suggestions
      , cancer_diagnosis_abstractions.has_cancer_site
      , cancer_diagnosis_abstractions.has_cancer_site_suggestions
      , cancer_diagnosis_abstractions.has_cancer_site_laterality
      , cancer_diagnosis_abstractions.has_cancer_who_grade
      , cancer_diagnosis_abstractions.has_metastatic_cancer_primary_site
      , cancer_diagnosis_abstractions.has_cancer_recurrence_status
      , cancer_abstractions.has_idh1_status
      , cancer_abstractions.has_idh2_status
      , cancer_abstractions.has_1p_status
      , cancer_abstractions.has_19q_status
      , cancer_abstractions.has_10q_PTEN_status AS has_10q_pten_status
      , cancer_abstractions.has_mgmt_status
      , cancer_abstractions.has_ki67
      , cancer_abstractions.has_p53
      , cancer_abstractions.has_surgery_date
from(
select    p.person_source_value
        , n.note_id
        , nsi.stable_identifier_path    as note_stable_identifier_path
        , nsi.stable_identifier_value_1 as note_stable_identifier_value_1
        , nsi.stable_identifier_value_2 as note_stable_identifier_value_2
        , posi1.stable_identifier_path                     as pathology_stable_identifier_path
        , posi1.stable_identifier_value_1                  as pathology_stable_identifier_value_1
        , posi1.stable_identifier_value_1                  as accession_nbr_formatted

--         , pr1.procedure_occurrence_id         as pathoogy_procedure_occurrence_id
        , pr1.procedure_date                  as pathology_procedure_date
--         , prv1.provider_id                    as pathology_provider_id
        , prv1.provider_name                  as pathology_provider_name
        , pr1.procedure_source_value          as pathology_procedure_source_value
        , c1.concept_name                     as pathology_concept_name

        , posi2.stable_identifier_path        as surgery_stable_identifier_path
        , posi2.stable_identifier_value_1     as surgery_stable_identifier_value_1
        , posi2.stable_identifier_value_1     as surgery_surgical_case_number
--         , pr2.procedure_occurrence_id         as surgery_procedure_occurrence_id
        , pr2.procedure_date                  as surgery_procedure_date
--         , prv2.provider_id                    as surgery_provider_id
        , prv2.provider_name                  as surgery_provider_name
        , pr2.procedure_source_value          as surgery_procedure_source_value
        , c2.concept_name                     as surgery_concept_name
        , n.note_title
        , n.note_text
-- from note_stable_identifier_full nsf  join note_stable_identifier nsi on nsf.stable_identifier_value = nsi.stable_identifier_value
from note_stable_identifier nsi
                                      join note n on nsi.note_id = n.note_id
                                      join person p on n.person_id = p.person_id
                                      join fact_relationship fr1 on n.note_id = fr1.fact_id_1 and fr1.domain_concept_id_1 = 5085 and fr1.relationship_concept_id  = 44818790
                                      join procedure_occurrence pr1 on fr1.fact_id_2 = pr1.procedure_occurrence_id and fr1.domain_concept_id_2 = 10
                                      join procedure_occurrence_stable_identifier posi1 on pr1.procedure_occurrence_id = posi1.procedure_occurrence_id
                                      join concept c1 on pr1.procedure_concept_id = c1.concept_id
                                      join provider prv1 on pr1.provider_id = prv1.provider_id
                                      join fact_relationship fr2 on fr2.domain_concept_id_1 = 10 and pr1.procedure_occurrence_id = fr2.fact_id_1 and fr2.relationship_concept_id = 44818888 and fr2.domain_concept_id_2 = 10
                                      join procedure_occurrence pr2 on fr2.fact_id_2 = pr2.procedure_occurrence_id
                                      join procedure_occurrence_stable_identifier posi2 on pr2.procedure_occurrence_id = posi2.procedure_occurrence_id
                                      join concept c2 on pr2.procedure_concept_id = c2.concept_id
                                      join provider prv2 on pr2.provider_id = prv2.provider_id
) data JOIN cancer_diagnosis_abstractions ON data.note_id = cancer_diagnosis_abstractions.note_id
       JOIN cancer_abstractions ON data.note_id = cancer_abstractions.note_id
WHERE cancer_diagnosis_abstractions.abstractor_namespace_name = 'Surgical Pathology';

--outside
INSERT INTO primary_cns_pathology_cases
(
  abstractor_namespace_name
, west_mrn
, note_stable_identifier_path
, note_stable_identifier_value_1
, note_stable_identifier_value_2
, note_id
, pathology_stable_identifier_path
, pathology_stable_identifier_value_1
, pathology_procedure_date
, pathology_provider_name
, pathology_procedure_source_value
, pathology_concept_name
-- , surgery_stable_identifier_path
-- , surgery_stable_identifier_value_1
-- , surgery_procedure_date
-- , surgery_provider_name
-- , surgery_procedure_source_value
-- , surgery_concept_name
, diagnosis_type
, has_cancer_histology
, has_cancer_histology_suggestions
, integrated_mention
, has_cancer_integrated_histology
, has_cancer_integrated_histology_suggestions
, has_cancer_site
, has_cancer_site_suggestions
, has_cancer_site_laterality
, has_cancer_who_grade
, has_metastatic_cancer_primary_site
, has_cancer_recurrence_status
, has_idh1_status
, has_idh2_status
, has_1p_status
, has_19q_status
, has_10q_pten_status
, has_mgmt_status
, has_ki67
, has_p53
, has_surgery_date
)
SELECT  cancer_diagnosis_abstractions.abstractor_namespace_name
      , data.person_source_value                          AS west_mrn
      , data.note_stable_identifier_path
      , data.note_stable_identifier_value_1
      , data.note_stable_identifier_value_2
      , data.note_id
      , data.pathology_stable_identifier_path
      , data.pathology_stable_identifier_value_1
      , data.pathology_procedure_date
      , data.pathology_provider_name
      , data.pathology_procedure_source_value
      , data.pathology_concept_name
      -- , data.surgery_stable_identifier_path
      -- , data.surgery_stable_identifier_value_1
      -- , data.surgery_procedure_date
      -- , data.surgery_provider_name
      -- , data.surgery_procedure_source_value
      -- , data.surgery_concept_name
      , cancer_diagnosis_abstractions.diagnosis_type
      , cancer_diagnosis_abstractions.has_cancer_histology
      , cancer_diagnosis_abstractions.has_cancer_histology_suggestions
      , case when data.note_text like '%integrated histology%' or data.note_text like '%integrated-histology%' or data.note_text like '%integrated diagnosis%' or data.note_text like '%integrated-diagnosis%' then 'yes' else 'no' end as integrated_mention
      , cancer_abstractions.has_cancer_integrated_histology
      , cancer_abstractions.has_cancer_integrated_histology_suggestions
      , cancer_diagnosis_abstractions.has_cancer_site
      , cancer_diagnosis_abstractions.has_cancer_site_suggestions
      , cancer_diagnosis_abstractions.has_cancer_site_laterality
      , cancer_diagnosis_abstractions.has_cancer_who_grade
      , cancer_diagnosis_abstractions.has_metastatic_cancer_primary_site
      , cancer_diagnosis_abstractions.has_cancer_recurrence_status
      , cancer_abstractions.has_idh1_status
      , cancer_abstractions.has_idh2_status
      , cancer_abstractions.has_1p_status
      , cancer_abstractions.has_19q_status
      , cancer_abstractions.has_10q_PTEN_status AS has_10q_pten_status
      , cancer_abstractions.has_mgmt_status
      , cancer_abstractions.has_ki67
      , cancer_abstractions.has_p53
      , cancer_abstractions.has_surgery_date

from(
select    p.person_source_value
        , n.note_id
        , nsi.stable_identifier_path    as note_stable_identifier_path
        , nsi.stable_identifier_value_1 as note_stable_identifier_value_1
        , nsi.stable_identifier_value_2 as note_stable_identifier_value_2
        , posi1.stable_identifier_path                     as pathology_stable_identifier_path
        , posi1.stable_identifier_value_1                  as pathology_stable_identifier_value_1
        , posi1.stable_identifier_value_1                  as accession_nbr_formatted
--         , pr1.procedure_occurrence_id         as pathoogy_procedure_occurrence_id
        , pr1.procedure_date                  as pathology_procedure_date
--         , prv1.provider_id                    as pathology_provider_id
        , prv1.provider_name                  as pathology_provider_name
        , pr1.procedure_source_value          as pathology_procedure_source_value
        , c1.concept_name                     as pathology_concept_name

        , NULL                                as surgery_stable_identifier_path
        , NULL                                as surgery_stable_identifier_value_1
        , NULL                                as surgery_surgical_case_number
--         , pr2.procedure_occurrence_id         as surgery_procedure_occurrence_id
        , NULL                                as surgery_procedure_date
--         , prv2.provider_id                    as surgery_provider_id
        , NULL                                as surgery_provider_name
        , NULL                                as surgery_procedure_source_value
        , NULL                                as surgery_concept_name
        , n.note_title
        , n.note_text
-- from note_stable_identifier_full nsf  join note_stable_identifier nsi on nsf.stable_identifier_value = nsi.stable_identifier_value
from note_stable_identifier nsi
                                      join note n on nsi.note_id = n.note_id
                                      join person p on n.person_id = p.person_id
                                      join fact_relationship fr1 on n.note_id = fr1.fact_id_1 and fr1.domain_concept_id_1 = 5085 and fr1.relationship_concept_id  = 44818790
                                      join procedure_occurrence pr1 on fr1.fact_id_2 = pr1.procedure_occurrence_id and fr1.domain_concept_id_2 = 10
                                      join procedure_occurrence_stable_identifier posi1 on pr1.procedure_occurrence_id = posi1.procedure_occurrence_id
                                      join concept c1 on pr1.procedure_concept_id = c1.concept_id
                                      join provider prv1 on pr1.provider_id = prv1.provider_id
) data JOIN cancer_diagnosis_abstractions ON data.note_id = cancer_diagnosis_abstractions.note_id
       JOIN cancer_abstractions ON data.note_id = cancer_abstractions.note_id
WHERE cancer_diagnosis_abstractions.abstractor_namespace_name = 'Outside Surgical Pathology';