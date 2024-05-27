require 'csv'
# metastatic
  # data
  # bundle exec rake setup:truncate_stable_identifiers
  # bundle exec rake omop:truncate_omop_clinical_data_tables
  # bundle exec rake setup:metastatic_data
  # bundle exec rake setup:metastatic_data[""]

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake metastatic:schemas

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will
  # bundle exec rake suggestor:do_multiple_will["?"]
  # bundle exec rake metastatic:create_pathology_cases_datamart
  # bundle exec rake metastatic:normalize
namespace :metastatic do
  desc 'Load schemas'
  task(schemas: :environment) do |t, args|
    date_object_type = Abstractor::AbstractorObjectType.where(value: 'date').first
    list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
    boolean_object_type = Abstractor::AbstractorObjectType.where(value: 'boolean').first
    string_object_type = Abstractor::AbstractorObjectType.where(value: 'string').first
    number_object_type = Abstractor::AbstractorObjectType.where(value: 'number').first
    radio_button_list_object_type = Abstractor::AbstractorObjectType.where(value: 'radio button list').first
    dynamic_list_object_type = Abstractor::AbstractorObjectType.where(value: 'dynamic list').first
    text_object_type = Abstractor::AbstractorObjectType.where(value: 'text').first
    name_value_rule = Abstractor::AbstractorRuleType.where(name: 'name/value').first
    value_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
    unknown_rule = Abstractor::AbstractorRuleType.where(name: 'unknown').first
    source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
    source_type_custom_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'custom nlp suggestion').first
    indirect_source_type = Abstractor::AbstractorAbstractionSourceType.where(name: 'indirect').first
    abstractor_section_type_offsets = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_OFFSETS).first
    abstractor_section_mention_type_alphabetic = Abstractor::AbstractorSectionMentionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_MENTION_TYPE_ALPHABETIC).first
    abstractor_section_mention_type_token = Abstractor::AbstractorSectionMentionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_MENTION_TYPE_TOKEN).first
    abstractor_section_specimen = Abstractor::AbstractorSection.where(abstractor_section_type: abstractor_section_type_offsets, name: 'SPECIMEN', source_type: NoteStableIdentifier.to_s, source_method: 'note_text', return_note_on_empty_section: true, abstractor_section_mention_type: abstractor_section_mention_type_alphabetic).first_or_create
    abstractor_section_comment = Abstractor::AbstractorSection.where(abstractor_section_type: abstractor_section_type_offsets, name: 'COMMENT', source_type: NoteStableIdentifier.to_s, source_method: 'note_text', return_note_on_empty_section: true, abstractor_section_mention_type: abstractor_section_mention_type_token).first_or_create
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'Comment')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'Comments')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'Note')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'Notes')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'Additional comment')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'Additional comments')
    abstractor_section_comment.save!
    abstractor_section_staging_summary = Abstractor::AbstractorSection.where(abstractor_section_type: abstractor_section_type_offsets, name: 'STAGING SUMMARY', source_type: NoteStableIdentifier.to_s, source_method: 'note_text', return_note_on_empty_section: true, abstractor_section_mention_type: abstractor_section_mention_type_token).first_or_create

    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'CANCER STAGING SUMMARY')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'TUMOR STAGING SUMMARY')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Tumor Staging Summary')

    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Adrenal Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Ampullary Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Anal (Excludes Rectal) Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Appendiceal (Including Goblet Cell Adenocarcinoma) Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Appendiceal (Including Goblet Cell Carcinoid Only) Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Appendiceal (Including Goblet Cell Carcinoma Only) Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Appendiceal Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Appendiceal Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Bone Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Cervical Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Colorectal Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Distal/Extrahepatic Bile Duct Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Esophageal and Esophagogastric Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Extra hepatic cholangiocarcinoma Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Gallbladder Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Gastric Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Gastrointestinal Stromal Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Gestational Trophoblastic Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Invasive Breast Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Jejunum and Ileum Neuroendocrine Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'LEFT BREAST - Invasive Breast Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Laryngeal Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Lip and Oral Cavity Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'MALIGNANT PLEURAL MESOTHELIOMA: Cancer Staging Summary (pTNM, AJCC 8th Edition, 2017)')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Microinvasive Breast Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Nasal Cavity and Paranasal Sinuses Cancer Staging Summary (AJCC 8th Edition, 2017)')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Ovarian Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Ovarian/Fallopian Tube Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Pancreatic (Endocrine) Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Pancreatic (Exocrine) Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Pancreatic Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Parotid Gland Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Penile Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Perihilar Bile Duct Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Pharynx (Oropharynx) Cancer Staging Summary (pTNM, AJCC 8th Edition, 2017)')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Pharynx (Oropharynx, Hypopharynx, Nasopharynx) Cancer Staging Summary (pTNM, AJCC 8th Edition, 2017)')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Prostatic Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Pulmonary Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'RIGHT BREAST - Invasive Breast Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Renal Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Renal Pelvic and Ureteral Tumor Staging')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Salivary Gland Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Skin Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Small Bowel Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Soft Tissue Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Testicular Tumor Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Thymic Epithelial Tumor Staging Summary (AJCC 8th Edition, 2017)')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Thyroid Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Ureteral Tumor Staging')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Urethral Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Urinary Bladder Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Uterine Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Vaginal Cancer Staging Summary')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name:'Vulvar Cancer Staging Summary')
    abstractor_section_staging_summary.save!

    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Final Diagnosis', 'Final Pathologic Diagnosis', 'Final Diagnosis Rendered')").first_or_create

    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_staging_summary)
    abstractor_namespace_surgical_pathology.save!

    #Begin metastatic
    metastatic_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Metastatic Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    metastatic_histologies = Icdo3Histology.by_metastasis
    metastatic_histologies.each do |histology|
      name = histology.icdo3_name.downcase
      if histology.icdo3_code != histology.icdo3_name
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology.icdo3_code})".downcase, vocabulary_code: histology.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: 'ICD-O-3.2').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => name.downcase).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = Icdo3Histology.by_icdo3_code_with_synonyms(histology.icdo3_code)
      histology_synonyms.each do |histology_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(histology_synonym.icdo3_synonym_description.downcase.downcase)
        normalized_values.each do |normalized_value|
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end
    end

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8000/6').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8010/6').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 1).first_or_create

    #Begin metastatic cancer site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    sites = Icdo3Site.by_primary
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.icdo3_name} (#{site.icdo3_code})".downcase, vocabulary_code: site.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: '2019 Updates to ICD-O-3.2').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.icdo3_name.downcase).first_or_create


      normalized_values = OmopAbstractor::Setup.normalize(site.icdo3_name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      site_synonyms = Icdo3Site.by_icdo3_code_with_synonyms(site.icdo3_code)
      site_synonyms.each do |site_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(site_synonym.icdo3_synonym_description.downcase)
        normalized_values.each do |normalized_value|
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end
    end

    #keep as create, not first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer site

    #Begin metastatic cancer primary site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_primary_site',
      display_name: 'Primary Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'primary cancer site').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'primary').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'originating').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'origin').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'spread from').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'metastasis from').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'consistent with').first_or_create

    sites = Icdo3Site.by_primary
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.icdo3_name} (#{site.icdo3_code})".downcase, vocabulary_code: site.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: '2019 Updates to ICD-O-3.2').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.icdo3_name.downcase).first_or_create


      normalized_values = OmopAbstractor::Setup.normalize(site.icdo3_name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      site_synonyms = Icdo3Site.by_icdo3_code_with_synonyms(site.icdo3_code)
      site_synonyms.each do |site_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(site_synonym.icdo3_synonym_description.downcase)
        normalized_values.each do |normalized_value|
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end
    end

    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C41.9').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!
    #
    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C49.9').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!
    #
    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C41.2').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create

    #End metastatic cancer primary site

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create
    lateralites = ['bilateral', 'left', 'right']
    lateralites.each do |laterality|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: laterality, vocabulary_code: laterality).first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End Laterality

    # #Begin Tumor Staging
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'tumor_staging',
    #   display_name: 'Tumor Staging',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'Tumor Staging').first_or_create
    #
    # abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Cancer Staging', vocabulary_code: 'Cancer Staging').first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => 'Tumor Staging').first_or_create
    # Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # #End Tumor Staging

    # #Begin recurrent
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_recurrence_status',
    #   display_name: 'Recurrent',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'recurrent').first_or_create
    #
    # #keep as create, not first_or_create
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 5).first_or_create
    #
    # #End recurrent

    #End metastatic

    # abstractor_namespace_outside_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    # "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
    #  JOIN note ON note_stable_identifier_full.note_id = note.note_id
    #  JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
    #  JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    # where_clause: "note.note_title IN('Final Diagnosis', 'Final Diagnosis Rendered')").first_or_create
    #
    # abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    # abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    # abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_staging_summary)
    # abstractor_namespace_outside_surgical_pathology.save!
    #
    # #Begin primary cancer
    # primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_histology',
    #   display_name: 'Histology',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'cancer histology').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: true).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create
    #
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_site',
    #   display_name: 'Site',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'cancer site').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create
    #
    # #End primary cancer
    #
    # #Begin surgery date
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_surgery_date',
    #   display_name: 'Surgery Date',
    #   abstractor_object_type: date_object_type,
    #   preferred_name: 'Surgery Date').first_or_create
    #
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'collected').first_or_create
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'collected on').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    # #End surgery date
  end

  #bundle exec rake metastatic:create_pathology_cases_datamart
  desc "Create Metastatic Pathology Cases Datamart"
  task(create_pathology_cases_datamart: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE metastatic_pathology_cases CASCADE;')
    sql_file = "#{Rails.root}/lib/tasks/metastatic_pathology_cases.sql"
    sql = File.read(sql_file)
    ActiveRecord::Base.connection.execute(sql)
  end

  #bundle exec rake metastatic:normalize
  desc "Normalize"
  task(normalize: :environment) do |t, args|
    MetastaticPathologyCase.where("has_cancer_histology IS NULL AND has_cancer_histology_suggestions  = 'carcinoma, metastatic (8010/6), neoplasm, metastatic (8000/6)'").update_all(has_cancer_histology: 'carcinoma, metastatic (8010/6)')

    MetastaticPathologyCase.where("has_cancer_histology IS NOT NULL AND has_cancer_histology != 'not applicable' AND has_metastatic_cancer_primary_site IS NOT NULL AND has_metastatic_cancer_primary_site != 'not applicable' AND has_cancer_site IS NULL AND has_cancer_site_suggestions IS NOT NULL").all.each do |metastatic_pathology_case|
      puts 'hello'
      puts "has_metastatic_cancer_primary_site: #{metastatic_pathology_case.has_metastatic_cancer_primary_site}"
      puts 'metastatic_pathology_case.has_cancer_site_suggestions'
      puts metastatic_pathology_case.has_cancer_site_suggestions
      has_cancer_site_suggestions = metastatic_pathology_case.has_cancer_site_suggestions.split(',').map(&:strip)
      has_cancer_site_suggestions = has_cancer_site_suggestions - [metastatic_pathology_case.has_metastatic_cancer_primary_site]
      puts 'how many left?'
      puts has_cancer_site_suggestions.size
      if has_cancer_site_suggestions.size == 1
        metastatic_pathology_case.has_cancer_site = has_cancer_site_suggestions.first
        metastatic_pathology_case.save!
      end
      puts 'goodbye'
    end

    metastatic_histology_synonyms = CSV.new(File.open('lib/setup/vocabulary/legacy_icdo3_metastatic_histology_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    maps = metastatic_histology_synonyms.map { |metastatic_histology_synonym| { icdo3_description: metastatic_histology_synonym['icdo3_description'], icdo3_synonym_description: metastatic_histology_synonym['icdo3_synonym_description'], icdo3_site_code: metastatic_histology_synonym['icdo3_site_code'] } }
    MetastaticPathologyCase.where("(has_cancer_histology IS NULL OR has_cancer_histology != 'not applicable') AND has_metastatic_cancer_primary_site IS NULL").all.each do |metastatic_pathology_case|
      icdo3_site_codes = []
      has_cancer_histology_suggestion_match_values = metastatic_pathology_case.has_cancer_histology_suggestion_match_values.split('|')
      has_cancer_histology_suggestion_match_values = has_cancer_histology_suggestion_match_values.map { |has_cancer_histology_suggestion_match_value| has_cancer_histology_suggestion_match_value.downcase }.uniq

      has_cancer_histology_suggestion_match_values.each do |has_cancer_histology_suggestion_match_value|
        detected_maps = maps.select{ |map| map[:icdo3_synonym_description] == has_cancer_histology_suggestion_match_value.downcase }
        icdo3_site_codes = icdo3_site_codes + detected_maps.map{ |detected_map| detected_map[:icdo3_site_code] }.uniq
      end

      icdo3_site_codes = icdo3_site_codes - ['*']
      puts 'how many icdo3_site_codes?'
      if icdo3_site_codes.size == 1
        puts 'we got one!'
        puts icdo3_site_codes.first
        has_cancer_histology_suggestion_match_values.each do |has_cancer_histology_suggestion_match_value|
          puts has_cancer_histology_suggestion_match_value
        end
        metastatic_pathology_case.has_metastatic_cancer_primary_site = icdo3_site_codes.first
        puts metastatic_pathology_case.west_mrn
        metastatic_pathology_case.save!
      end
    end
  end
end
