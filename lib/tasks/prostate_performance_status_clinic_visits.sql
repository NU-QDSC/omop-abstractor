-- TRUNCATE TABLE prostate_performance_status_clinic_visits;

DROP TABLE IF EXISTS cancer_abstractions;

CREATE TEMPORARY TABLE cancer_abstractions
(
 id                                           BIGINT        NOT NULL,
 note_id                                      BIGINT        NOT NULL,
 stable_identifier_path                       varchar(255)  NULL,
 stable_identifier_value                      varchar(255)  NULL,
 subject_id                                   BIGINT        NOT NULL ,
 has_ecog_performance_status                  varchar(255)  NULL,
 has_karnofsky_performance_status             varchar(255)  NULL,
 abstractor_namespace_name                varchar(255)  NULL,
 about_id                                     BIGINT        NOT NULL
);

INSERT INTO cancer_abstractions (
   id
 , note_id
 , stable_identifier_path
 , stable_identifier_value
 , subject_id
 , has_ecog_performance_status
 , has_karnofsky_performance_status
 , abstractor_namespace_name
 , about_id
)
SELECT note_stable_identifier.id
     , note_stable_identifier_full.note_id
     , note_stable_identifier.stable_identifier_path
     , note_stable_identifier.stable_identifier_value
     , pivoted_abstractions.subject_id
     , pivoted_abstractions.has_ecog_performance_status
     , pivoted_abstractions.has_karnofsky_performance_status
     , pivoted_abstractions.abstractor_namespace_name
     , pivoted_abstractions.about_id
FROM note_stable_identifier JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     LEFT JOIN (SELECT note_stable_identifier.id AS subject_id,
                       Max(CASE
                             WHEN data.predicate = 'has_ecog_performance_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_ecog_performance_status,
                       Max(CASE
                             WHEN data.predicate = 'has_karnofsky_performance_status' THEN
                             data.value
                             ELSE NULL
                           END)                  AS has_karnofsky_performance_status,
                      abstractor_namespace_name,
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
                               END    AS value,
                               an.name AS abstractor_namespace_name
                        FROM   abstractor_abstractions aa
                               JOIN abstractor_subjects asb
                                 ON aa.abstractor_subject_id = asb.id
                               JOIN abstractor_abstraction_schemas aas
                                 ON asb.abstractor_abstraction_schema_id =
                                    aas.id
                              JOIN abstractor_namespaces an ON asb.namespace_id = an.id AND asb.namespace_type = 'Abstractor::AbstractorNamespace'
                        WHERE  asb.subject_type = 'NoteStableIdentifier'
                               AND asb.namespace_type =
                                   'Abstractor::AbstractorNamespace'
                               AND asb.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Clinic Visits'))
                               AND aa.deleted_at IS NULL
                               AND NOT
                       EXISTS (SELECT 1
                               FROM   abstractor_abstraction_group_members
                                      aagm
                               WHERE  aa.id = aagm.abstractor_abstraction_id))
                       data
                       JOIN note_stable_identifier
                         ON data.about_id = note_stable_identifier.id
                GROUP  BY note_stable_identifier.id, data.about_id, data.abstractor_namespace_name) pivoted_abstractions
            ON pivoted_abstractions.subject_id = note_stable_identifier.id
WHERE  ( EXISTS (SELECT 1
               FROM   abstractor_abstractions aa
                      JOIN abstractor_subjects sub
                        ON aa.abstractor_subject_id = sub.id
                           AND sub.namespace_type =
                               'Abstractor::AbstractorNamespace'
                           AND sub.namespace_id IN(SELECT id FROM abstractor_namespaces WHERE name IN('Clinic Visits'))
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

SELECT *
FROM cancer_abstractions;

-- INSERT INTO prostate_performance_status_clinic_visits
-- (
--   abstractor_namespace_name
-- , west_mrn
-- , note_stable_identifier_path
-- , note_stable_identifier_value_1
-- , note_stable_identifier_value_2
-- , note_id
-- , note_date
-- , has_ecog_performance_status
-- , has_karnofsky_performance_status
-- )

-- SELECT
--         cancer_abstractions.abstractor_namespace_name
--       , data.person_source_value                          AS west_mrn
--       , data.note_stable_identifier_path
--       , data.note_stable_identifier_value_1
--       , data.note_stable_identifier_value_2
--       , data.note_id
--       , data.note_date
--       , cancer_abstractions.has_ecog_performance_status
--       , cancer_abstractions.has_karnofsky_performance_status
-- from(
-- select    p.person_source_value
--         , n.note_id
--         , n.note_date
--         , nsi.stable_identifier_path    as note_stable_identifier_path
--         , nsi.stable_identifier_value_1 as note_stable_identifier_value_1
--         , nsi.stable_identifier_value_2 as note_stable_identifier_value_2
-- -- from note_stable_identifier_full nsf  join note_stable_identifier nsi on nsf.stable_identifier_value = nsi.stable_identifier_value
-- from note_stable_identifier nsi
--                                       join note n on nsi.note_id = n.note_id
--                                       join person p on n.person_id = p.person_id
-- ) data JOIN cancer_abstractions ON data.note_id = cancer_abstractions.note_id
-- WHERE cancer_abstractions.abstractor_namespace_name = 'Clinic Visits';

--coercion
SELECT  data.person_source_value                          AS west_mrn
      , 'ECOG'                                            AS performance_status_type
      , cancer_abstractions.has_ecog_performance_status   AS performance_status
      , cancer_abstractions.has_ecog_performance_status   AS performance_status_normalized
      , data.note_date                                    AS performance_status_datetime

from(
select    p.person_source_value
        , n.note_id
        , n.note_date
        , nsi.stable_identifier_path    as note_stable_identifier_path
        , nsi.stable_identifier_value_1 as note_stable_identifier_value_1
        , nsi.stable_identifier_value_2 as note_stable_identifier_value_2
-- from note_stable_identifier_full nsf  join note_stable_identifier nsi on nsf.stable_identifier_value = nsi.stable_identifier_value
from note_stable_identifier nsi
                                      join note n on nsi.note_id = n.note_id
                                      join person p on n.person_id = p.person_id
) data JOIN cancer_abstractions ON data.note_id = cancer_abstractions.note_id
WHERE cancer_abstractions.abstractor_namespace_name = 'Clinic Visits'
AND cancer_abstractions.has_ecog_performance_status != 'not applicable'
UNION
SELECT  data.person_source_value                          AS west_mrn
      , 'ECOG'                                            AS performance_status_type
      , cancer_abstractions.has_karnofsky_performance_status   AS performance_status
      , cancer_abstractions.has_karnofsky_performance_status   AS performance_status_normalized
      , data.note_date                                    AS performance_status_datetime

from(
select    p.person_source_value
        , n.note_id
        , n.note_date
        , nsi.stable_identifier_path    as note_stable_identifier_path
        , nsi.stable_identifier_value_1 as note_stable_identifier_value_1
        , nsi.stable_identifier_value_2 as note_stable_identifier_value_2
-- from note_stable_identifier_full nsf  join note_stable_identifier nsi on nsf.stable_identifier_value = nsi.stable_identifier_value
from note_stable_identifier nsi
                                      join note n on nsi.note_id = n.note_id
                                      join person p on n.person_id = p.person_id
) data JOIN cancer_abstractions ON data.note_id = cancer_abstractions.note_id
WHERE cancer_abstractions.abstractor_namespace_name = 'Clinic Visits'
AND cancer_abstractions.has_karnofsky_performance_status != 'not applicable'

-- SELECT *
-- FROM prostate_performance_status_clinic_visits
-- -- WHERE west_mrn IN(
-- -- ?
-- -- )
-- -- AND surgery_procedure_source_value IS NOT NULL
-- ORDER BY west_mrn, note_date