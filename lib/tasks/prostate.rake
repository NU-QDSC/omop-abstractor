# ohdsi nlp proposal
  # data
  # bundle exec rake setup:truncate_stable_identifiers
  # bundle exec rake omop:truncate_omop_clinical_data_tables
  # bundle exec rake setup:prostate_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake prostate:schemas
  # bundle exec rake prostate:schemas_biopsy

  #abstraction will
  # bundle exec rake suggestor:do_multiple_will
  # bundle exec rake prostate:create_prostate_pathology_cases_datamart

namespace :prostate do
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
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'prostatic cancer staging summary')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'PROSTATIC CANCER STAGING SUMMARY')
    abstractor_section_comment.save!

    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Conversion Final Diagnosis', 'Final Diagnosis',  'Final Diagnosis Rendered', 'Final Pathologic Diagnosis', 'AP SYNOPTIC REPORTS', 'Synoptic Reports')").first_or_create

    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_surgical_pathology.save!

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    prostate_histologies = Icdo3Histology.by_primary_prostate
    prostate_histologies.each do |histology|
      name = histology.icdo3_name.downcase
      if histology.icdo3_code != histology.icdo3_name
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology.icdo3_code})".downcase, vocabulary_code: histology.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: 'ICD-O-3.2').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => name).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = Icdo3Histology.by_icdo3_code_with_synonyms(histology.icdo3_code)
      histology_synonyms.each do |histology_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(histology_synonym.icdo3_synonym_description.downcase)
        normalized_values.each do |normalized_value|
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8010/3').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    prostate_sites = Icdo3Site.by_primary_prostate
    prostate_sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.icdo3_name} (#{site.icdo3_code})".downcase, vocabulary_code: site.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: '2019 ICD-O-3.2').first_or_create
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

    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C50.9').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create

    # #Begin Laterality
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_site_laterality',
    #   display_name: 'Laterality',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'laterality').first_or_create
    # lateralites = ['bilateral', 'left', 'right']
    # lateralites.each do |laterality|
    #   abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: laterality, vocabulary_code: laterality).first_or_create
    #   Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    # end
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create
    #
    # #End Laterality

    # #Begin recurrent
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_recurrence_status',
    #   display_name: 'Recurrent',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'recurrent').first_or_create
    #
    # abstractor_object_value_initial = Abstractor::AbstractorObjectValue.where(value: 'initial', vocabulary_code: 'initial').first_or_create
    # Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value_initial).first_or_create
    #
    # abstractor_object_value_recurrent = Abstractor::AbstractorObjectValue.where(value: 'recurrent', vocabulary_code: 'recurrent').first_or_create
    # Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value_recurrent).first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value_recurrent, value: 'residual').first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value_recurrent, value: 'recurrence').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    #
    #End recurrent

    #End primary cancer
    # #Begin metastatic
    # metastatic_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Metastatic Cancer', enable_workflow_status: false).first_or_create
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_histology',
    #   display_name: 'Histology',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'cancer histology').first_or_create
    #
    # metastatic_histologies = Icdo3Histology.by_metastasis
    # metastatic_histologies.each do |histology|
    #   name = histology.icdo3_name.downcase
    #   if histology.icdo3_code != histology.icdo3_name
    #     abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology.icdo3_code})".downcase, vocabulary_code: histology.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: 'ICD-O-3.2').first_or_create
    #   else
    #     abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
    #   end
    #
    #   Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    #   Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => name.downcase).first_or_create
    #
    #   normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
    #   normalized_values.each do |normalized_value|
    #     if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
    #       Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
    #     end
    #   end
    #
    #   histology_synonyms = Icdo3Histology.by_icdo3_code_with_synonyms(histology.icdo3_code)
    #   histology_synonyms.each do |histology_synonym|
    #     normalized_values = OmopAbstractor::Setup.normalize(histology_synonym.icdo3_synonym_description.downcase.downcase)
    #     normalized_values.each do |normalized_value|
    #       Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
    #     end
    #   end
    # end
    #
    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8000/6').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: true).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 1).first_or_create
    #
    # #Begin metastatic cancer site
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_site',
    #   display_name: 'Metastatic Site',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'metastatic cancer site').first_or_create
    #
    #
    # sites = Icdo3Site.by_primary_metastatic_prostate
    # sites.each do |site|
    #   abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.icdo3_name} (#{site.icdo3_code})".downcase, vocabulary_code: site.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: '2019 Updates to ICD-O-3.2').first_or_create
    #   Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    #   Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.icdo3_name.downcase).first_or_create
    #
    #
    #   normalized_values = OmopAbstractor::Setup.normalize(site.icdo3_name.downcase)
    #   normalized_values.each do |normalized_value|
    #     if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
    #       Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
    #     end
    #   end
    #
    #   site_synonyms = Icdo3Site.by_icdo3_code_with_synonyms(site.icdo3_code)
    #   site_synonyms.each do |site_synonym|
    #     normalized_values = OmopAbstractor::Setup.normalize(site_synonym.icdo3_synonym_description.downcase)
    #     normalized_values.each do |normalized_value|
    #       Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
    #     end
    #   end
    # end
    #
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
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create
    # #End metastatic cancer site
    #
    # #Begin metastatic cancer primary site
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_primary_site',
    #   display_name: 'Primary Site',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'primary cancer site').first_or_create
    #
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'primary').first_or_create
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'originating').first_or_create
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'origin').first_or_create
    #
    # prostate_sites = Icdo3Site.by_primary_prostate
    # prostate_sites.each do |site|
    #   abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.icdo3_name} (#{site.icdo3_code})".downcase, vocabulary_code: site.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: '2019 ICD-O-3.2').first_or_create
    #   Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    #   Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.icdo3_name.downcase).first_or_create
    #
    #   normalized_values = OmopAbstractor::Setup.normalize(site.icdo3_name.downcase)
    #   normalized_values.each do |normalized_value|
    #     if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
    #       Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
    #     end
    #   end
    #
    #   site_synonyms = Icdo3Site.by_icdo3_code_with_synonyms(site.icdo3_code)
    #   site_synonyms.each do |site_synonym|
    #     normalized_values = OmopAbstractor::Setup.normalize(site_synonym.icdo3_synonym_description.downcase)
    #     normalized_values.each do |normalized_value|
    #       Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
    #     end
    #   end
    # end
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create
    # #End metastatic cancer primary site
    #
    # #Begin Laterality
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_site_laterality',
    #   display_name: 'Metastatic Laterality',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'laterality').first_or_create
    #
    # lateralites = ['bilateral', 'left', 'right']
    # lateralites.each do |laterality|
    #   abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: laterality, vocabulary_code: laterality).first_or_create
    #   Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    # end
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create
    # #End Laterality

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

    # #Begin tumor size
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_tumor_size',
    #   display_name: 'tumor size',
    #   abstractor_object_type: number_object_type,
    #   preferred_name: 'tumor size').first_or_create
    #
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'size').first_or_create
    # Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'prostate greatest dimension').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # #End tumor size

    #Begin prostate weight
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_prostate_weight',
      display_name: 'prostate weight',
      abstractor_object_type: number_object_type,
      preferred_name: 'prostate weight').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'weight').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End prostate weight

    #Begin Gleason Score Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_gleason_score_grade',
      display_name: 'Gleason Score Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'gleason score grade').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'gleason grade').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: "gleason's grade").first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'gleason score').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: "gleason's score").first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: "gleason's").first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'primary + secondary').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3+3', vocabulary_code: '3+3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+3=6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 3 = 6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 3=6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+3= 6').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3+4', vocabulary_code: '3+4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+4=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 4 = 7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 4=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+4= 7').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4+3', vocabulary_code: '4+3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+3=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 3 = 7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 3=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+3= 7').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4+4', vocabulary_code: '4+4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+4=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 4 = 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 4=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+4= 8').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3+5', vocabulary_code: '3+5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 5').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+5=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 5 = 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 5=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+5= 8').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5+3', vocabulary_code: '5+3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+3=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 3 = 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 3=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+3= 8').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4+5', vocabulary_code: '4+5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 5').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+5=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 5 = 9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 5=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+5= 9').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5+4', vocabulary_code: '5+4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+4=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 4 = 9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 4=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+4= 9').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5+5', vocabulary_code: '5+5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 5').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+5=10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 5 = 10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 5=10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+5= 10').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    #End Gleason Score Grade

    #Begin pT Category
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'pathological_tumor_staging_category',
      display_name: 'pT Category',
      abstractor_object_type: list_object_type,
      preferred_name: 'pT').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'staging').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'stage').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'tumor (t)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'tumor(t)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'tumor (t):').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'tumor(t):').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pTx', vocabulary_code: 'pTx').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTx').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'TX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_TX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT2', vocabulary_code: 'pT2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T2').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT2a', vocabulary_code: 'pT2a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT2a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T2a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T2a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT2b', vocabulary_code: 'pT2b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT2b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T2b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T2b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT2c', vocabulary_code: 'pT2c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT2c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T2c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T2c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT3', vocabulary_code: 'pT3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T3').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT3a', vocabulary_code: 'pT3a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT3a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T3a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T3a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT3b', vocabulary_code: 'pT3b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT3b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T3b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T3b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT4', vocabulary_code: 'pT4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T4').first_or_create

    #begin yp
    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypTx', vocabulary_code: 'ypTx').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTx').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yTX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yTX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT2', vocabulary_code: 'ypT2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT2').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT2a', vocabulary_code: 'ypT2a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT2a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT2a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT2a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT2b', vocabulary_code: 'ypT2b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT2b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT2b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT2b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT2c', vocabulary_code: 'ypT2c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT2c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT2c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT2c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT3', vocabulary_code: 'ypT3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT3').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT3a', vocabulary_code: 'ypT3a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT3a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT3a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT3a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT3b', vocabulary_code: 'ypT3b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT3b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT3b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT3b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT4', vocabulary_code: 'ypT4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT4').first_or_create
    #end yp

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End pT Category

    #Begin pN Category
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'pathological_nodes_staging_category',
      display_name: 'pN Category',
      abstractor_object_type: list_object_type,
      preferred_name: 'pN').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'staging').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'stage').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'node').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'nodes (n)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'nodes(n)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'nodes (n):').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'nodes(n):').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'node (n)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'node(n)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'node (n):').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'node(n):').first_or_create


    # abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN', vocabulary_code: 'pN').first_or_create
    # Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN').first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N').first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pNX', vocabulary_code: 'pNX').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pNX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'NX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_NX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN0', vocabulary_code: 'pN0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N0').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN1', vocabulary_code: 'pN1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N1').first_or_create

    #begin ypn
    # abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN', vocabulary_code: 'ypN').first_or_create
    # Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN').first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN').first_or_create
    # Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypNX', vocabulary_code: 'ypNX').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypNX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yNX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yNX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN0', vocabulary_code: 'ypN0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN0').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN1', vocabulary_code: 'ypN1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN1').first_or_create
    #end ypn

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End pN Category

    #Begin pM Category
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'pathological_metastasis_staging_category',
      display_name: 'pM Category',
      abstractor_object_type: list_object_type,
      preferred_name: 'pM').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'staging').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'stage').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'metastasis (m)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'metastasis (m):').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'metastasis(m)').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'metastasis(m):').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pM0', vocabulary_code: 'pM0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pM0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'M0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_M0').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pMX', vocabulary_code: 'pMX').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pMX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'MX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_MX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pM1', vocabulary_code: 'pM1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pM1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'M1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_M1').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pM1a', vocabulary_code: 'pM1a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pM1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'M1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_M1a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pM1b', vocabulary_code: 'pM1b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pM1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'M1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_M1b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pM1c', vocabulary_code: 'pM1c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pM1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'M1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_M1c').first_or_create

    #begin ypm
    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypM0', vocabulary_code: 'ypM0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypM0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yM0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yM0').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypMX', vocabulary_code: 'ypMX').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypMX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yMX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yMX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypM1', vocabulary_code: 'ypM1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypM1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yM1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yM1').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypM1a', vocabulary_code: 'ypM1a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypM1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yM1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yM1a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypM1b', vocabulary_code: 'ypM1b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypM1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yM1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yM1b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypM1c', vocabulary_code: 'ypM1c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypM1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yM1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yM1c').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #end ypm
    #End pN Category

    #Begin Extraprostatic Extension
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_extraprostatic_extension',
      display_name: 'Extraprostatic Extension',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'extraprostatic extension').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'epe').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'extra prostatic extension').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'extra-prostatic extension').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'not identified', vocabulary_code: 'not identified').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'none').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'absent').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'negative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'present', vocabulary_code: 'present').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'identified').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'establish').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'established').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'noted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'positive').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Extraprostatic Extension

    #Begin Seminal Vesicle Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_seminal_vesicle_invasion',
      display_name: 'Seminal Vesicle Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'seminal vesicle invasion').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'seminal vesicles').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'not identified', vocabulary_code: 'not identified').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'free').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'negative').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'benign').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'present', vocabulary_code: 'present').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'identified').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'positive').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Seminal Vesicle Invasion

    #Begin Lymphovascular Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_lymphovascular_invasion',
      display_name: 'Lymphovascular Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'lymphovascular invasion').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'lymphatic or vascular invasion').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'not identified', vocabulary_code: 'not identified').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'negative').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not established').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'free').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'none').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not observed').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'absent').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not seen').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no evidence').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'present', vocabulary_code: 'present').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'identified').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'positive').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'established').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'extensive').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'seen').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'confirms').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymphovascular Invasion

    #Begin Perineural Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_perineural_invasion',
      display_name: 'Perineural Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'perineural invasion').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'not identified', vocabulary_code: 'not identified').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'negative').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'absent').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not seen').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'none').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'present', vocabulary_code: 'present').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'identified').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'positive').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'noted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'seen').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'established').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'extensive').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Perineural Invasion

    #Begin Margin Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_margin_status',
      display_name: 'Margin Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'margin').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'margins').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involved').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'uninvolved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'uninvolving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'free').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involving').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Margin Status

    #Begin Lymph Nodes Examined
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_number_lymph_nodes_examined',
      display_name: 'Lymph Nodes Examined',
      abstractor_object_type: number_object_type,
      preferred_name: 'lymph nodes examined').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'number of lymph nodes examined').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'total lymph nodes').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymph Nodes Examined

    #Begin Lymph Nodes Positive Tumor
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_number_lymph_nodes_positive_tumor',
      display_name: 'Lymph Nodes Positive Tumor',
      abstractor_object_type: number_object_type,
      preferred_name: 'lymph nodes positive tumor').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'number positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'number of lymph nodes involved').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymph Nodes Positive Tumor

    #Outside Surgical Pathology
    abstractor_namespace_outside_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    where_clause: "note.note_title in('Conversion Final Diagnosis', 'Final Diagnosis',  'Final Diagnosis Rendered', 'Final Pathologic Diagnosis', 'AP SYNOPTIC REPORTS', 'Synoptic Reports')").first_or_create

    abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_outside_surgical_pathology.save!

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    #End primary cancer
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create

    # #Begin Laterality
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_site_laterality',
    #   display_name: 'Laterality',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'laterality').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create
    #
    # #End Laterality

    # #Begin recurrent
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_cancer_recurrence_status',
    #   display_name: 'Recurrent',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'recurrent').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 5).first_or_create
    #
    # #End recurrent

    #End primary cancer
    # #Begin metastatic
    # metastatic_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Metastatic Cancer', enable_workflow_status: false).create
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_histology',
    #   display_name: 'Histology',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'cancer histology').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: true).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 1).first_or_create
    #
    # #Begin metastatic cancer site
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_site',
    #   display_name: 'Metastatic Site',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'metastatic cancer site').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create
    #
    # #End metastatic cancer site
    #
    # #Begin metastatic cancer primary site
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_primary_site',
    #   display_name: 'Primary Site',
    #   abstractor_object_type: list_object_type,
    #   preferred_name: 'primary cancer site').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create
    #
    # #End metastatic cancer primary site
    #
    # #Begin Laterality
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_metastatic_cancer_site_laterality',
    #   display_name: 'Metastatic Laterality',
    #   abstractor_object_type: radio_button_list_object_type,
    #   preferred_name: 'laterality').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).create
    # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create
    #
    # #End Laterality
    #
    # # #Begin recurrent
    # # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    # #   predicate: 'has_cancer_recurrence_status',
    # #   display_name: 'Recurrent',
    # #   abstractor_object_type: radio_button_list_object_type,
    # #   preferred_name: 'recurrent').first_or_create
    # #
    # # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).create
    # # abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 5).first_or_create
    # #
    # # #End recurrent
    #
    # #End metastatic

    #Begin surgery date
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_surgery_date',
      display_name: 'Surgery Date',
      abstractor_object_type: date_object_type,
      preferred_name: 'Surgery Date').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'collected').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'collected on').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create

    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    #End surgery date

    # #Begin tumor size
    # abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
    #   predicate: 'has_tumor_size',
    #   display_name: 'tumor size',
    #   abstractor_object_type: number_object_type,
    #   preferred_name: 'tumor size').first_or_create
    #
    # abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    # Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    # #End tumor size

    #Begin prostate weight
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_prostate_weight',
      display_name: 'prostate weight',
      abstractor_object_type: number_object_type,
      preferred_name: 'prostate weight').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End tumor size

    #Begin Gleason Score Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_gleason_score_grade',
      display_name: 'Gleason Score Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'gleason score grade').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Gleason Score Grade

    #Begin pT Category
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'pathological_tumor_staging_category',
      display_name: 'pT Category',
      abstractor_object_type: list_object_type,
      preferred_name: 'pT').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End pT Category

    #Begin pN Category
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'pathological_nodes_staging_category',
      display_name: 'pN Category',
      abstractor_object_type: list_object_type,
      preferred_name: 'pN').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End pN Category

    #Begin pM Category
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'pathological_metastasis_staging_category',
      display_name: 'pM Category',
      abstractor_object_type: list_object_type,
      preferred_name: 'pM').first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End pM Category

    #Begin Extraprostatic Extension
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_extraprostatic_extension',
      display_name: 'Extraprostatic Extension',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'extraprostatic extension').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Extraprostatic Extension

    #Begin Seminal Vesicle Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_seminal_vesicle_invasion',
      display_name: 'Seminal Vesicle Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'seminal vesicle invasion').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Seminal Vesicle Invasion

    #Begin Lymphovascular Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_lymphovascular_invasion',
      display_name: 'Lymphovascular Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'lymphovascular invasion').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymphovascular Invasion

    #Begin Perineural Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_perineural_invasion',
      display_name: 'Perineural Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'perineural invasion').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Perineural Invasion

    #Begin Margin Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_margin_status',
      display_name: 'Margin Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'margin').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Margin Status

    #Begin Lymph Nodes Examined
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_number_lymph_nodes_examined',
      display_name: 'Lymph Nodes Examined',
      abstractor_object_type: number_object_type,
      preferred_name: 'lymph nodes examined').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Extraprostatic Extension

    #Begin Lymph Nodes Positive Tumor
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_number_lymph_nodes_positive_tumor',
      display_name: 'Lymph Nodes Positive Tumor',
      abstractor_object_type: number_object_type,
      preferred_name: 'lymph nodes positive tumor').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Extraprostatic Extension
  end

  desc 'Load schemas biopsy'
  task(schemas_biopsy: :environment) do |t, args|
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
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'prostatic cancer staging summary')
    abstractor_section_comment.abstractor_section_name_variants.build(name: 'PROSTATIC CANCER STAGING SUMMARY')
    abstractor_section_comment.save!

    abstractor_namespace_surgical_pathology_biopsy = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology Biopsy', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Conversion Final Diagnosis', 'Final Diagnosis',  'Final Diagnosis Rendered', 'Final Pathologic Diagnosis', 'AP SYNOPTIC REPORTS', 'Synoptic Reports')").first_or_create

    abstractor_namespace_surgical_pathology_biopsy.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_surgical_pathology_biopsy.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_surgical_pathology_biopsy.save!

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    #Begin Histology
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    prostate_histologies = Icdo3Histology.by_primary_prostate
    prostate_histologies.each do |histology|
      name = histology.icdo3_name.downcase
      if histology.icdo3_code != histology.icdo3_name
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology.icdo3_code})".downcase, vocabulary_code: histology.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: 'ICD-O-3.2').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => name).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = Icdo3Histology.by_icdo3_code_with_synonyms(histology.icdo3_code)
      histology_synonyms.each do |histology_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(histology_synonym.icdo3_synonym_description.downcase)
        normalized_values.each do |normalized_value|
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology_biopsy.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8010/3').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    #End Histology

    #Begin Prostate Biopsy
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_prostate_biopsy',
      display_name: 'Prostate Biopsy',
      abstractor_object_type: list_object_type,
      preferred_name: 'prostate_biopsy').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'biopsy').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'biopsies').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'excision').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'excisions').first_or_create

    prostate_sites = Icdo3Site.by_primary_prostate
    prostate_sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.icdo3_name} (#{site.icdo3_code})".downcase, vocabulary_code: site.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: '2019 ICD-O-3.2').first_or_create
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

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create
    #End Prostate Biopsy

    #Begin Gleason Score Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_gleason_score_grade',
      display_name: 'Gleason Score Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'gleason score grade').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'gleason grade').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: "gleason's grade").first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'gleason score').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: "gleason's score").first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: "gleason's").first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'primary + secondary').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3+3', vocabulary_code: '3+3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+3=6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+3= 6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 3 = 6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 3=6').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+3= 6').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3+4', vocabulary_code: '3+4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+4=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+4= 7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 4 = 7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 4=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+4= 7').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4+3', vocabulary_code: '4+3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+3=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 3 = 7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 3=7').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+3= 7').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4+4', vocabulary_code: '4+4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+4=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+4= 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 4 = 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 4=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+4= 8').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3+5', vocabulary_code: '3+5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 5').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+5=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+5= 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 5 = 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3 + 5=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '3+5= 8').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5+3', vocabulary_code: '5+3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+3=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+3= 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 3 = 8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 3=8').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+3= 8').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4+5', vocabulary_code: '4+5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 5').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+5=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+5= 9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 5 = 9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4 + 5=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '4+5= 9').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5+4', vocabulary_code: '5+4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+4=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+4= 9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 4 = 9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 4=9').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+4= 9').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5+5', vocabulary_code: '5+5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 5').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+5=10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+5= 10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 5 = 10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5 + 5=10').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '5+5= 10').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create
    #End Gleason Score Grade

    #Begin Positive Cores of Cores
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_positive_cores_of_cores',
      display_name: 'Positive Cores of Cores',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'positive cores of cores').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '0 of 1 cores', vocabulary_code: '0 of 1 cores').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '0 of 1 core').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'zero of one cores').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'zero of one core').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'zero of 1 cores').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'zero of 1 core').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '1 of 1 cores', vocabulary_code: '1 of 1 cores').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in one cores").first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in 1 cores").first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in one (1) cores").first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving one cores").first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving one (1) cores").first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving one (1) different cores").first_or_create

    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '1 of 1 core').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'one of one cores').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'one of one core').first_or_create

    (2..12).each do |i|
      (0..i).each do |j|
        i_word = I18n.with_locale(:en) { i.to_words }
        j_word = I18n.with_locale(:en) { j.to_words }
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: "#{j} of #{i} cores", vocabulary_code: "#{j} of #{i} cores").first_or_create
        Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i_word} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} out of #{i_word} cores").first_or_create

        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} of #{i} core biopsies").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i_word} core biopsies").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} of #{i_word} core biopsies").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i} core biopsies").first_or_create

        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} out of #{i} core biopsies").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i_word} core biopsies").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} out of #{i_word} core biopsies").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i} core biopsies").first_or_create

        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in #{i_word} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in #{i} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in #{i_word} (#{i}) cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving #{i_word} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving #{i_word} (#{i}) cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving #{i_word} (#{i}) different cores").first_or_create

        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i_word} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i} cores").first_or_create
        Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} of #{i_word} cores").first_or_create

        ['inked', 'uninked', 'non inked', 'non-inked', 'noninked'].each do |ink|
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i_word} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} out of #{i_word} #{ink} cores").first_or_create


          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} of #{i} #{ink} core biopsies").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i_word} #{ink} core biopsies").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} of #{i_word} #{ink} core biopsies").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i} #{ink} core biopsies").first_or_create

          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} out of #{i} #{ink} core biopsies").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i_word} #{ink} core biopsies").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} out of #{i_word} #{ink} core biopsies").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} out of #{i} #{ink} core biopsies").first_or_create

          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in #{i_word} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in #{i} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "in #{i_word} (#{i}) #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving #{i_word} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving #{i_word} (#{i}) #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "involving #{i_word} (#{i}) different #{ink} cores").first_or_create

          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i_word} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j_word} of #{i} #{ink} cores").first_or_create
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: "#{j} of #{i_word} #{ink} cores").first_or_create
        end
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    #End Positive Cores of Cores

    #Begin Perineural Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_perineural_invasion',
      display_name: 'Perineural Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'perineural invasion').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'not identified', vocabulary_code: 'not identified').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'negative').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not involving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'absent').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not seen').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'none').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'present', vocabulary_code: 'present').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'identified').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'positive').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'noted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'seen').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'demonstrated').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'established').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involved').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'involving').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'extensive').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology_biopsy.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 5).first_or_create
    #End Perineural Invasion

    #Outside Surgical Pathology
    abstractor_namespace_outside_surgical_pathology_biopsy = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology Biopsy', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    where_clause: "note.note_title in('Conversion Final Diagnosis', 'Final Diagnosis',  'Final Diagnosis Rendered', 'Final Pathologic Diagnosis', 'AP SYNOPTIC REPORTS', 'Synoptic Reports')").first_or_create

    abstractor_namespace_outside_surgical_pathology_biopsy.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_outside_surgical_pathology_biopsy.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_outside_surgical_pathology_biopsy.save!

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology_biopsy.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    #Begin Prostate Biopsy
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_prostate_biopsy',
      display_name: 'Prostate Biopsy',
      abstractor_object_type: list_object_type,
      preferred_name: 'prostate_biopsy').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create
    #End Prostate Biopsy

    #Begin Gleason Score Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_gleason_score_grade',
      display_name: 'Gleason Score Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'gleason score grade').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Gleason Score Grade

    #Begin Positive Cores of Cores
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_positive_cores_of_cores',
      display_name: 'Positive Cores of Cores',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'positive cores of cores').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    #End Positive Cores of Cores

    #Begin Perineural Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_perineural_invasion',
      display_name: 'Perineural Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'perineural invasion').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology_biopsy.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 5).first_or_create
    #end Perineural Invasion
    #End primary cancer

    #Begin surgery date
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_surgery_date',
      display_name: 'Surgery Date',
      abstractor_object_type: date_object_type,
      preferred_name: 'Surgery Date').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'collected').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'collected on').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'reported on').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology_biopsy.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create

    # Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    # Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    #End surgery date
  end

  #bundle exec rake aml:create_aml_pathology_cases_datamart
  desc "Create Prostate Pathology Cases Datamart"
  task(create_prostate_pathology_cases_datamart: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE prostate_pathology_cases CASCADE;')
    sql_file = "#{Rails.root}/lib/tasks/prostate_pathology_cases.sql"
    sql = File.read(sql_file)
    ActiveRecord::Base.connection.execute(sql)
  end
end