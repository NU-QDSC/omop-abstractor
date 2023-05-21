require './lib/omop_abstractor/setup/setup'
require './lib/tasks/omop_abstractor_clamp_dictionary_exporter'
require 'csv'
namespace :biorepository_breast_new do
  desc 'Load schemas breast'
  task(schemas_breast: :environment) do |t, args|
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
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name: 'BREAST CANCER STAGING SUMMARY')
    abstractor_section_staging_summary.abstractor_section_name_variants.build(name: 'Breast Cancer Staging Summary')
    abstractor_section_staging_summary.save!

    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Final Diagnosis', 'Final Pathologic Diagnosis', 'AP FINAL DIAGNOSIS', 'AP SYNOPTIC REPORTS')").first_or_create

    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_staging_summary)
    abstractor_namespace_surgical_pathology.save!

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    breast_histologies = Icdo3Histology.by_primary_breast
    breast_histologies.each do |histology|
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
        if !['ductal carcinoma, nos', 'duct carcinoma, nos', 'ductal carcinoma', 'duct carcinoma'].include?(histology_synonym.icdo3_synonym_description.downcase)
          normalized_values = OmopAbstractor::Setup.normalize(histology_synonym.icdo3_synonym_description.downcase)
          normalized_values.each do |normalized_value|
            Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
          end
        end
      end
    end

    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8000/0').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!
    #
    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '8000/3').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!
    #
    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '9380/3').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    breast_sites = Icdo3Site.by_primary_breast
    breast_sites.each do |site|
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

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C50.9').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create

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
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin Pathologic SBR Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_pathologic_sbr_grade',
      display_name: 'Pathologic Scarff-Bloom-Richardson Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'grade').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 1', vocabulary_code: 'Grade 1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade I').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 2', vocabulary_code: 'Grade 2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade II').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 3', vocabulary_code: 'Grade 3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade III').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End Pathologic SBR Grade

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_object_value_initial = Abstractor::AbstractorObjectValue.where(value: 'initial', vocabulary_code: 'initial').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value_initial).first_or_create

    abstractor_object_value_recurrent = Abstractor::AbstractorObjectValue.where(value: 'recurrent', vocabulary_code: 'recurrent').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value_recurrent).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value_recurrent, value: 'residual').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value_recurrent, value: 'recurrence').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End primary cancer
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

    sites = Icdo3Site.by_primary_metastatic_breast
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

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C41.9').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C49.9').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: 'C41.2').first
    abstractor_object_value.favor_more_specific = true
    abstractor_object_value.save!

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

    #keep as create, not first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End Laterality

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    #keep as create, not first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 5).first_or_create

    #End recurrent

    #End metastatic

    #Begin tumor size
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_tumor_size',
      display_name: 'tumor size',
      abstractor_object_type: number_object_type,
      preferred_name: 'tumor size').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'tumor extent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End tumor size

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

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT0', vocabulary_code: 'pT0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T0').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pTis (DCIS)', vocabulary_code: 'pTis (DCIS)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTis (DCIS)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pTis(DCIS)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTis(DCIS)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Tis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_Tis').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pTis (Paget)', vocabulary_code: 'pTis (Paget)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTis (Paget)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pTis(Paget)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTis(Paget)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Tis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_Tis').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT1', vocabulary_code: 'pT1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T1').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT1mi', vocabulary_code: 'pT1mi').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T1mi').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT1a', vocabulary_code: 'pT1a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T1a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT1b', vocabulary_code: 'pT1b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T1b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT1c', vocabulary_code: 'pT1c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T1c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT2', vocabulary_code: 'pT2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T2').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT3', vocabulary_code: 'pT3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T3').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT4', vocabulary_code: 'pT4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T4').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT4a', vocabulary_code: 'pT4a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT4a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T4a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T4a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT4b', vocabulary_code: 'pT4b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT4b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T4b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T4b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT4c', vocabulary_code: 'pT4c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT4c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T4c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T4c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pT4d', vocabulary_code: 'pT4d').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pT4d').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'T4d').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_T4d').first_or_create

    #begin yp
    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypTx', vocabulary_code: 'ypTx').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTx').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yTX').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yTX').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT0', vocabulary_code: 'ypT0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT0').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT0').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypTis (DCIS)', vocabulary_code: 'ypTis (DCIS)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTis (DCIS)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'ypTis(DCIS)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTis(DCIS)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'ypTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yTis').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypTis (Paget)', vocabulary_code: 'ypTis (Paget)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTis (Paget)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'ypTis(Paget)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTis(Paget)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'ypTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yTis').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yTis').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT1', vocabulary_code: 'ypT1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT1').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT1').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT1mi', vocabulary_code: 'ypT1mi').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT1mi').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT1a', vocabulary_code: 'ypT1a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT1a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT1b', vocabulary_code: 'ypT1b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT1b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT1c', vocabulary_code: 'ypT1c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT1c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT2', vocabulary_code: 'ypT2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT2').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT2').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT3', vocabulary_code: 'ypT3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT3').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT3').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT4', vocabulary_code: 'ypT4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT4').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT4').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT4a', vocabulary_code: 'ypT4a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT4a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT4a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT4a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT4b', vocabulary_code: 'ypT4b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT4b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT4b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT4b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT4c', vocabulary_code: 'ypT4c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT4c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT4c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT4c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypT4d', vocabulary_code: 'ypT4d').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypT4d').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yT4d').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yT4d').first_or_create
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

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN0 (i+)', vocabulary_code: 'pN0 (i+)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN0 (i+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N0 (i+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N0 (i+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N0i+').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N0i+').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN0 (mol+)', vocabulary_code: 'pN0 (mol+)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN0 (mol+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N0 (mol+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N0 (mol+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N0mol+').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N0mol+').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN1mi', vocabulary_code: 'pN1mi').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N1mi').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN1a', vocabulary_code: 'pN1a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N1a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN1b', vocabulary_code: 'pN1b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N1b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN1c', vocabulary_code: 'pN1c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N1c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'pN3c', vocabulary_code: 'pN3c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_pN3c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'N3c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_N3c').first_or_create

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

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN0 (i+)', vocabulary_code: 'ypN0 (i+)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN0 (i+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN0 (i+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN0 (i+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN0i+').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN0i+').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN0 (mol+)', vocabulary_code: 'ypN0 (mol+)').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_YpN0 (mol+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN0 (mol+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN0 (mol+)').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN0mol+').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN0mol+').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN1mi', vocabulary_code: 'ypN1mi').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN1mi').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN1mi').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN1a', vocabulary_code: 'ypN1a').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN1a').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN1a').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN1b', vocabulary_code: 'ypN1b').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN1b').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN1b').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN1c', vocabulary_code: 'ypN1c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN1c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN1c').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'ypN3c', vocabulary_code: 'ypN3c').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_ypN3c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yN3c').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '_yN3c').first_or_create

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

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create

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

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #end ypm

    #End pN Category

    #Begin Estrogen Receptor Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_estrogen_receptor_status',
      display_name: 'Estrogen Receptor Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'er status').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'estrogen receptor').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'estrogen receptor status').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'estrogen receptor (er) status').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'er').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create

    #End Estrogen Receptor Status

    #Begin Progesterone Receptor Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_progesterone_receptor_status',
      display_name: 'Progesterone Receptor Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'pr status').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'progesterone receptor').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'progesterone receptor status').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'progesterone receptor (pgr) status').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'pr').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'PR').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create

    #End Progesterone Receptor Status

    #Begin HER2 Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_her2_status',
      display_name: 'HER2 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'her2').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'her2/neu').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'her-2/neu').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'erbb2').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'cd340').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'tyrosine-protein kinase erbb-2').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'proto-oncogene neu').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'positive', vocabulary_code: 'positive').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'yes').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'pos.').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'affirmative').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'negative', vocabulary_code: 'negative').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'no').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'neg.').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create

    #End HER2 Status

    #Begin Lymphovascular Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_lymphovascular_invasion',
      display_name: 'Lymphovascular Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'lymphovascular invasion').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'lymph-vascular Invasion').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'not identified', vocabulary_code: 'not identified').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'present', vocabulary_code: 'present').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymphovascular Invasion

    #Begin ki67
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_ki67',
      display_name: 'ki67',
      abstractor_object_type: number_object_type,
      preferred_name: 'ki67').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'ki-67').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'mib-1').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'mib1').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End ki67

    #Begin p53
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_p53',
      display_name: 'p53',
      abstractor_object_type: number_object_type,
      preferred_name: 'p53').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'p-53').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'p 53').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End p53

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
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'number of positive versus total').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymph Nodes Positive Tumor

    abstractor_namespace_outside_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    where_clause: "note.note_title IN('Final Diagnosis', 'Final Pathologic Diagnosis', 'AP FINAL DIAGNOSIS')").first_or_create

    abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_specimen)
    abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_comment)
    abstractor_namespace_outside_surgical_pathology.abstractor_namespace_sections.build(abstractor_section: abstractor_section_staging_summary)
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

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Laterality

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

    #Begin Pathologic SBR Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_pathologic_sbr_grade',
      display_name: 'Pathologic Scarff-Bloom-Richardson Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'grade').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End Pathologic SBR Grade

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 5).first_or_create

    #End recurrent

    #End primary cancer
    #Begin metastatic
    metastatic_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Metastatic Cancer', enable_workflow_status: false).create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 1).first_or_create

    #Begin metastatic cancer site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer site

    #Begin metastatic cancer primary site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_primary_site',
      display_name: 'Primary Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'primary cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create

    #End metastatic cancer primary site

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End Laterality

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 5).first_or_create
    #End recurrent
    #End metastatic

    #Begin Tumor Size
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_tumor_size',
      display_name: 'tumor size',
      abstractor_object_type: number_object_type,
      preferred_name: 'tumor size').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Tumor Size

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

    #Begin Estrogen Receptor Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_estrogen_receptor_status',
      display_name: 'Estrogen Receptor Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'er status').first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Estrogen Receptor Status#End pM Category

    #Begin Progesterone Receptor Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_progesterone_receptor_status',
      display_name: 'Progesterone Receptor Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'pr status').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Progesterone Receptor Status

    #Begin HER2 Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_her2_status',
      display_name: 'HER2 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'her2').first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End HER2 Status

    #Begin Lymphovascular Invasion
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_lymphovascular_invasion',
      display_name: 'Lymphovascular Invasion',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'lymphovascular invasion').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End Lymphovascular Invasion

    #Begin ki67
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_ki67',
      display_name: 'ki67',
      abstractor_object_type: number_object_type,
      preferred_name: 'ki67').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End ki67

    #Begin p53
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_p53',
      display_name: 'p53',
      abstractor_object_type: number_object_type,
      preferred_name: 'p53').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    #End p53

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
    #End Lymph Nodes Positive Tumor
  end

  desc "Truncate stable identifiers"
  task(truncate_stable_identifiers: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
  end

  desc "Load Biorepository Breast data"
  task(biorepository_breast_data: :environment) do |t, args|
    files = ['lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 1.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 2.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 3.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 4.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 5.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 6.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 7.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 8.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 9.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 10.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 11.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 12.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 13.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 14.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 15.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 16.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 17.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 18.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 19.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 20.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 21.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 22.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 23.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 24.xlsx']
    # files = ['lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 6.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 7.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 8.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 9.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 10.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 11.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 12.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 13.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 14.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 15.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 16.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 17.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 18.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 19.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 20.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 21.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 22.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 23.xlsx', 'lib/setup/data/biorepository_breast/Specimen Collection Facility Pathology Cases with Surgeries 24.xlsx']

    @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
    @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first

    files.each do |file|
      biorepository_colon_pathology_procedures = Roo::Spreadsheet.open(file)
      pathology_procedure_map = {
         'west mrn' => 0,
         'source system' => 1,
         'stable identifier path' => 2,
         'stable identiifer value' => 3,
         'accession nbr formatted' => 4,
         'accessioned datetime'   => 5,
         'present map count' => 6,
         'surgical case key' => 7,
         'or case id' => 8,
         'surg case id' => 9,
         'cpt' => 10,
         'cpt description' => 11,
         'surgery name' => 12,
         'group name' => 13,
         'group desc' => 14,
         'snomed code' => 15,
         'snomed name' => 16,
         'group id' => 17,
         'responsible pathologist full name' => 18,
         'responsible pathologist npi' => 19,
         'primary surgeon full name' => 20,
         'primary surgeon npi' => 21,
         'section description' => 22,
         'note text' => 23,
      }

      pathology_procedures_by_mrn = {}

      location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
      gender_concept_id = Concept.genders.first.concept_id
      race_concept_id = Concept.races.first.concept_id
      ethnicity_concept_id =   Concept.ethnicities.first.concept_id

      for i in 2..biorepository_colon_pathology_procedures.sheet(0).last_row do
        puts 'row'
        puts i
        puts 'west mrn'
        west_mrn = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
        puts west_mrn

        #Person 1
        person = Person.where(gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location).first
        if person.blank?
          person_id = Person.maximum(:person_id)
          if person_id.nil?
            person_id = 1
          else
            person_id+=1
          end
          person = Person.new(person_id: person_id, gender_concept_id: gender_concept_id, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: race_concept_id, ethnicity_concept_id: ethnicity_concept_id, person_source_value: west_mrn, location: location)
          person.save!
          person.mrns.where(health_system: 'NMHC',  mrn: west_mrn).first_or_create
        end

        provider = Provider.where(provider_source_value: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']]).first
        if provider.blank?
          provider_id = Provider.maximum(:provider_id)
          if provider_id.nil?
            provider_id = 1
          else
            provider_id+=1
          end
          provider = Provider.new(provider_id: provider_id, provider_name: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], npi: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
          provider.save!
        end

        accession_nbr_formatted = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
        puts 'accession_nbr_formatted'
        puts accession_nbr_formatted
        accessioned_datetime = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
        accessioned_datetime = accessioned_datetime.to_date.to_s
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted).first
        if procedure_occurrence_stable_identifier.blank?
          puts 'not here yet'
          snomed_code = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
          puts 'snomed_code'
          puts snomed_code
          procedure_concept = Concept.where(concept_code: snomed_code, vocabulary_id: Concept::VOCABULARY_ID_SNOMED).first
          if procedure_concept
            procedure_concept_id = procedure_concept.concept_id
          else
            procedure_concept_id = 0
          end

          procedure_type_concept = Concept.procedure_types.where(concept_name: 'Secondary Procedure').first
          procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
          if procedure_occurrence_id.nil?
            procedure_occurrence_id = 1
          else
            procedure_occurrence_id+=1
          end

          procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: nil, procedure_source_concept_id: nil, modifier_source_value: nil)
          procedure_occurrence.save!
          procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted)
          procedure_occurrence_stable_identifier.save!
        else
          procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurrence_stable_identifier.procedure_occurrence_id).first
        end

        stable_identifier_path = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
        stable_identifier_value = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identiifer value']]

        note_stable_identifier = NoteStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)

        if note_stable_identifier.blank?
          note_title = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
          puts 'hello booch'
          puts pathology_procedure_map['section description']
          puts note_title
          note_text = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['note text']]
          note_id = Note.maximum(:note_id)
          if note_id.nil?
            note_id = 1
          else
            note_id+=1
          end

          note = Note.new(note_id: note_id, person_id: person.person_id, note_date: Date.parse(accessioned_datetime), note_datetime: Date.parse(accessioned_datetime), note_type_concept_id: @note_type_concept.concept_id, note_class_concept_id: @note_class_concept.concept_id, note_title: note_title, note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, note_source_value: nil)
          note.save!
          note_stable_identifier_full = NoteStableIdentifierFull.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)
          note_stable_identifier_full.save!

          note_stable_identifier = NoteStableIdentifier.new(note_id: note.note_id, stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)
          note_stable_identifier.save!

          domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
          domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
          relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
          relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
          FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_note.concept_id, fact_id_2: note.note_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
          FactRelationship.where(domain_concept_id_1: domain_concept_note.concept_id, fact_id_1: note.note_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
        end

        or_case_id = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['or case id']]
        surg_case_id = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surg case id']]

        surgery = false
        if or_case_id.present? && or_case_id != 0
          puts 'here 1'
          stable_identifier_path = 'or case id'
          stable_identifier_value_1 = or_case_id
          procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: or_case_id).first
          surgery = true
        end

        if surg_case_id.present? && surg_case_id != 0
          puts 'here 2'
          stable_identifier_path = 'surg_case_id'
          stable_identifier_value_1 = surg_case_id
          procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: surg_case_id).first
          surgery = true
        end

        if surgery && procedure_occurrence_stable_identifier.blank?
          cpt = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt']]
          surgery_name = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]

          if surgery_name
            surgery_name = surgery_name.truncate(50)
          end

          if cpt
            procedure_concept = Concept.standard.valid.where(vocabulary_id: Concept::CONCEPT_CLASS_CPT4, concept_code: cpt).first
            if procedure_concept.present?
              procedure_concept_id = procedure_concept.concept_id
            else
              procedure_concept_id = 0
            end
          else
            procedure_concept_id = 0
          end

          procedure_type_concept = Concept.procedure_types.where(concept_name: 'Primary Procedure').first
          procedure_occurrence_id = ProcedureOccurrence.maximum(:procedure_occurrence_id)
          if procedure_occurrence_id.nil?
            procedure_occurrence_id = 1
          else
            procedure_occurrence_id+=1
          end

          provider = Provider.where(provider_source_value: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']]).first
          if provider.blank?
            provider_id = Provider.maximum(:provider_id)
            if provider_id.nil?
              provider_id = 1
            else
              provider_id+=1
            end
            provider = Provider.new(provider_id: provider_id, provider_name: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], npi: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
            provider.save!
          end

          surgery_procedure_occurrence = ProcedureOccurrence.new(procedure_occurrence_id: procedure_occurrence_id, person_id: person.person_id, procedure_concept_id: procedure_concept_id, procedure_date: Date.parse(accessioned_datetime), procedure_datetime: Date.parse(accessioned_datetime), procedure_type_concept_id: procedure_type_concept.concept_id, modifier_concept_id: nil, quantity: 1, provider_id: (provider.present? ? provider.provider_id : nil), visit_occurrence_id: nil, procedure_source_value: surgery_name, procedure_source_concept_id: nil, modifier_source_value: nil)
          surgery_procedure_occurrence.save!
          procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.new(procedure_occurrence_id: procedure_occurrence_id, stable_identifier_path: stable_identifier_path, stable_identifier_value_1: stable_identifier_value_1)
          procedure_occurrence_stable_identifier.save!

          domain_concept_procedure = Concept.domain_concepts.where(concept_name: 'Procedure').first
          domain_concept_note = Concept.domain_concepts.where(concept_name: 'Note').first
          relationship_proc_context_of = Relationship.where(relationship_id: 'Proc context of').first
          relationship_has_proc_context = Relationship.where(relationship_id: 'Has proc context').first
          FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: surgery_procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_has_proc_context.relationship_concept_id).first_or_create
          FactRelationship.where(domain_concept_id_1: domain_concept_procedure.concept_id, fact_id_1: procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: domain_concept_procedure.concept_id, fact_id_2: surgery_procedure_occurrence.procedure_occurrence_id, relationship_concept_id: relationship_proc_context_of.relationship_concept_id).first_or_create
        end
      end
    end
  end

  desc "Load Breast Abstractions"
  task(biorepository_breast_abstractions: :environment) do |t, args|
    CompareBreastCancerAbstraction.delete_all
    compare_breast_cancer_abstractions_from_file = CSV.new(File.open('lib/setup/data/biorepository_breast/compare_breast_cancer_abstractions.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    compare_breast_cancer_abstractions_from_file.each do |compare_breast_cancer_abstraction_from_file|
      compare_breast_cancer_abstraction = CompareBreastCancerAbstraction.new
      compare_breast_cancer_abstraction.abstractor_namespace_name = compare_breast_cancer_abstraction_from_file['abstractor_namespace_name']
      compare_breast_cancer_abstraction.person_source_value = compare_breast_cancer_abstraction_from_file['person_source_value']
      compare_breast_cancer_abstraction.note_id = compare_breast_cancer_abstraction_from_file['note_id']
      compare_breast_cancer_abstraction.stable_identifier_path = compare_breast_cancer_abstraction_from_file['stable_identifier_path']
      compare_breast_cancer_abstraction.stable_identifier_value = compare_breast_cancer_abstraction_from_file['stable_identifier_value']
      compare_breast_cancer_abstraction.subject_id = compare_breast_cancer_abstraction_from_file['subject_id']
      compare_breast_cancer_abstraction.procedure_occurrence_stable_identifier_path = compare_breast_cancer_abstraction_from_file['procedure_occurrence_stable_identifier_path']
      compare_breast_cancer_abstraction.procedure_occurrence_stable_identifier_value = compare_breast_cancer_abstraction_from_file['procedure_occurrence_stable_identifier_value']
      compare_breast_cancer_abstraction.procedure_date = compare_breast_cancer_abstraction_from_file['procedure_date']
      compare_breast_cancer_abstraction.has_cancer_histology = compare_breast_cancer_abstraction_from_file['has_cancer_histology']
      compare_breast_cancer_abstraction.has_cancer_histology_suggestions = compare_breast_cancer_abstraction_from_file['has_cancer_histology_suggestions']
      compare_breast_cancer_abstraction.has_cancer_site = compare_breast_cancer_abstraction_from_file['has_cancer_site']
      compare_breast_cancer_abstraction.has_cancer_site_suggestions = compare_breast_cancer_abstraction_from_file['has_cancer_site_suggestions']
      compare_breast_cancer_abstraction.has_cancer_site_laterality = compare_breast_cancer_abstraction_from_file['has_cancer_site_laterality']
      compare_breast_cancer_abstraction.has_cancer_pathologic_sbr_grade = compare_breast_cancer_abstraction_from_file['has_cancer_pathologic_sbr_grade']
      compare_breast_cancer_abstraction.has_cancer_recurrence_status = compare_breast_cancer_abstraction_from_file['has_cancer_recurrence_status']
      compare_breast_cancer_abstraction.has_metastatic_cancer_histology = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_histology']
      compare_breast_cancer_abstraction.has_metastatic_cancer_histology_suggestions = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_histology_suggestions']
      compare_breast_cancer_abstraction.has_metastatic_cancer_site = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_site']
      compare_breast_cancer_abstraction.has_metastatic_cancer_site_suggestions = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_site_suggestions']
      compare_breast_cancer_abstraction.has_metastatic_cancer_primary_site = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_primary_site']
      compare_breast_cancer_abstraction.has_metastatic_cancer_site_laterality = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_site_laterality']
      compare_breast_cancer_abstraction.has_metastatic_cancer_recurrence_status = compare_breast_cancer_abstraction_from_file['has_metastatic_cancer_recurrence_status']
      compare_breast_cancer_abstraction.procedure_occurrence_stable_identifier_surgery_path = compare_breast_cancer_abstraction_from_file['procedure_occurrence_stable_identifier_surgery_path']
      compare_breast_cancer_abstraction.procedure_occurrence_stable_identifier_surgery_value = compare_breast_cancer_abstraction_from_file['procedure_occurrence_stable_identifier_surgery_value']
      compare_breast_cancer_abstraction.surgery_procedure_date = compare_breast_cancer_abstraction_from_file['surgery_procedure_date']
      compare_breast_cancer_abstraction.surgery_concept_name = compare_breast_cancer_abstraction_from_file['surgery_concept_name']
      compare_breast_cancer_abstraction.surgery_vocabulary_id = compare_breast_cancer_abstraction_from_file['surgery_vocabulary_id']
      compare_breast_cancer_abstraction.surgery_concept_code = compare_breast_cancer_abstraction_from_file['surgery_concept_code']
      compare_breast_cancer_abstraction.surgery_procedure_source_value = compare_breast_cancer_abstraction_from_file['surgery_procedure_source_value']
      compare_breast_cancer_abstraction.has_surgery_date = compare_breast_cancer_abstraction_from_file['has_surgery_date']
      compare_breast_cancer_abstraction.has_surgery_date_normalized = compare_breast_cancer_abstraction_from_file['has_surgery_date_normalized']
      compare_breast_cancer_abstraction.pathological_tumor_staging_category = compare_breast_cancer_abstraction_from_file['pathological_tumor_staging_category']
      compare_breast_cancer_abstraction.pathological_nodes_staging_category = compare_breast_cancer_abstraction_from_file['pathological_nodes_staging_category']
      compare_breast_cancer_abstraction.pathological_metastasis_staging_category = compare_breast_cancer_abstraction_from_file['pathological_metastasis_staging_category']
      compare_breast_cancer_abstraction.has_tumor_size = compare_breast_cancer_abstraction_from_file['has_tumor_size']
      compare_breast_cancer_abstraction.has_estrogen_receptor_status = compare_breast_cancer_abstraction_from_file['has_estrogen_receptor_status']
      compare_breast_cancer_abstraction.has_progesterone_receptor_status = compare_breast_cancer_abstraction_from_file['has_progesterone_receptor_status']
      compare_breast_cancer_abstraction.has_her2_status = compare_breast_cancer_abstraction_from_file['has_her2_status']
      compare_breast_cancer_abstraction.save!
    end
  end
end
