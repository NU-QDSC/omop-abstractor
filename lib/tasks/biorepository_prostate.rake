# 7th
# http://sxc.cancerstaging.org/references-tools/quickreferences/Documents/ProstateLarge.pdf

# 8th
# http://sxc.cancerstaging.org/CSE/Physician/Documents/AJCC_PPT%20-Prostate%20Webinar%20v3.pdf

require './lib/omop_abstractor/setup/setup'
require './lib/tasks/omop_abstractor_clamp_dictionary_exporter'
require 'redcap_api'
namespace :biorepository_prostate do
  desc "Fix"
  task(fix: :environment) do |t, args|
    stable_identifier_value_1s = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/stable_identifier_value_1s.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    stable_identifier_value_1s.each do |stable_identifier_value_1|
      procedure_occurrence_stable_identifiers = ProcedureOccurrenceStableIdentifier.where(stable_identifier_value_1: stable_identifier_value_1['stable_identifier_value_1'], stable_identifier_path: 'surgical case number').all
      procedure_occurrence_stable_identifiers = procedure_occurrence_stable_identifiers.to_a
      procedure_occurrence_stable_identifiers.shift
      procedure_occurrence_stable_identifiers.each do |procedure_occurrence_stable_identifier|
        procedure_occurrence = ProcedureOccurrence.where(procedure_occurrence_id: procedure_occurrence_stable_identifier.procedure_occurrence_id).first
        procedure_occurrence.destroy
        procedure_occurrence_stable_identifier.destroy
      end
    end
  end

  desc 'Load schemas OMOP Abstractor NLP biorepository prostate'
  task(schemas_omop_abstractor_nlp_biorepository_prostate: :environment) do |t, args|
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

  desc 'Load schemas OMOP Abstractor NLP biorepository prostate biopsy'
  task(schemas_omop_abstractor_nlp_biorepository_prostate_biopsy: :environment) do |t, args|
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

  desc "Truncate stable identifiers"
  task(truncate_stable_identifiers: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
  end

  desc "Load Biorepository Prostate data into the batch table"
  task(biorepository_prostate_batch_data: :environment) do |t, args|
    files = ['lib/setup/data/biorepository_prostate/Specimen Collection Facility Pathology Cases with Surgeries 1.xlsx', 'lib/setup/data/biorepository_prostate/Specimen Collection Facility Pathology Cases with Surgeries 2.xlsx', 'lib/setup/data/biorepository_prostate/Specimen Collection Facility Pathology Cases with Surgeries 3.xlsx', 'lib/setup/data/biorepository_prostate/Specimen Collection Facility Pathology Cases with Surgeries 4.xlsx', 'lib/setup/data/biorepository_prostate/Specimen Collection Facility Pathology Cases with Surgeries 5.xlsx']

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

      for i in 2..biorepository_colon_pathology_procedures.sheet(0).last_row do
        puts 'row'
        puts i
        batch_pathology_report_section = BatchPathologyReportSection.new
        batch_pathology_report_section.west_mrn = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
        batch_pathology_report_section.source_system = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['source system']]
        batch_pathology_report_section.stable_identifier_path = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
        batch_pathology_report_section.stable_identifier_value = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identiifer value']]
        batch_pathology_report_section.accession_nbr_formatted = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
        batch_pathology_report_section.accessioned_datetime = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
        batch_pathology_report_section.present_map_count = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['present map count']]
        batch_pathology_report_section.surgical_case_key = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case key']]
        batch_pathology_report_section.or_case_id = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['or case id']]
        batch_pathology_report_section.surg_case_id = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surg case id']]
        batch_pathology_report_section.cpt = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt']]
        batch_pathology_report_section.cpt_description = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt description']]
        batch_pathology_report_section.surgery_name = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]
        batch_pathology_report_section.group_name = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group name']]
        batch_pathology_report_section.group_desc = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group desc']]
        batch_pathology_report_section.snomed_code = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
        batch_pathology_report_section.snomed_name = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed name']]
        batch_pathology_report_section.group_id = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group id']]
        batch_pathology_report_section.responsible_pathologist_full_name = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]
        batch_pathology_report_section.responsible_pathologist_npi = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']]
        batch_pathology_report_section.primary_surgeon_full_name = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]
        batch_pathology_report_section.primary_surgeon_npi = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']]
        batch_pathology_report_section.section_description = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
        batch_pathology_report_section.note_text = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['note text']]
        batch_pathology_report_section.save!
      end
    end
  end

  desc "Load Biorepository Prostate data 2"
  task(biorepository_prostate_data_2: :environment) do |t, args|
    files = ['lib/setup/data/biorepository_prostate 2/Pathology Cases with Surgeries V2 1.xlsx', 'lib/setup/data/biorepository_prostate 2/Pathology Cases with Surgeries V2 2.xlsx', 'lib/setup/data/biorepository_prostate 2/Pathology Cases with Surgeries V2 3.xlsx']
    @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
    @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first

    files.each do |file|
      biorepository_colon_pathology_procedures = Roo::Spreadsheet.open(file)
      pathology_procedure_map = {
         'west mrn' => 0,
         'source system' => 1,
         'stable identifier path' => 2,
         'stable identiifer value' => 3,
         'case collect datetime'   => 4,
         'accessioned datetime'   => 5,
         'accession nbr formatted' => 6,
         'group name' => 7,
         'group desc' => 8,
         'group id' => 9,
         'snomed code' => 10,
         'snomed name' => 11,
         'responsible pathologist full name' => 12,
         'responsible pathologist npi' => 13,
         'section description' => 14,
         'note text' => 15,
         'surgical case number' => 16,
         'surgery name' => 17,
         'surgery start date' => 18,
         'code type' => 19,
         'cpt code' => 20,
         'cpt name' => 21,
         'primary surgeon full name' => 22,
         'primary surgeon npi' => 23,
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

        provider = Provider.where(provider_source_value: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]).first
        if provider.blank?
          provider_id = Provider.maximum(:provider_id)
          if provider_id.nil?
            provider_id = 1
          else
            provider_id+=1
          end
          provider = Provider.new(provider_id: provider_id, provider_name: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], npi: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
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

        surgical_case_number = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]

        surgery = false
        if surgical_case_number.present?
          puts 'here 1'
          stable_identifier_path = 'surgical case number'
          stable_identifier_value_1 = surgical_case_number
          procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: surgical_case_number).first
          surgery = true
        end

        if surgery && procedure_occurrence_stable_identifier.blank?
          cpt = biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
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

          provider = Provider.where(provider_source_value: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]).first
          if provider.blank?
            provider_id = Provider.maximum(:provider_id)
            if provider_id.nil?
              provider_id = 1
            else
              provider_id+=1
            end
            provider = Provider.new(provider_id: provider_id, provider_name: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], npi: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: biorepository_colon_pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
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

  desc "Load Biorepository Prostate data 3"
  task(biorepository_prostate_data_3: :environment) do |t, args|
    files = ['lib/setup/data/biorepository_prostate 2/prostate_spore_latest/Pathology Cases with Surgeries V2 Prostate SPORE Final Diagnosis.xlsx']
    @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
    @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first

    files.each do |file|
      pathology_procedures = Roo::Spreadsheet.open(file)
      pathology_procedure_map = {
         'west mrn' => 0,
         'source system' => 1,
         'stable identifier path' => 2,
         'stable identiifer value' => 3,
         'case collect datetime'   => 4,
         'accessioned datetime'   => 5,
         'accession nbr formatted' => 6,
         'group name' => 7,
         'group desc' => 8,
         'group id' => 9,
         'snomed code' => 10,
         'snomed name' => 11,
         'responsible pathologist full name' => 12,
         'responsible pathologist npi' => 13,
         'section description' => 14,
         'note text' => 15,
         'surgical case number' => 16,
         'surgery name' => 17,
         'surgery start date' => 18,
         'code type' => 19,
         'cpt code' => 20,
         'cpt name' => 21,
         'primary surgeon full name' => 22,
         'primary surgeon npi' => 23
      }



      pathology_procedures_by_mrn = {}

      location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
      gender_concept_id = Concept.genders.first.concept_id
      race_concept_id = Concept.races.first.concept_id
      ethnicity_concept_id =   Concept.ethnicities.first.concept_id

      for i in 2..pathology_procedures.sheet(0).last_row do
        batch_pathology_case_surgery = BatchPathologyCaseSurgery.new
        batch_pathology_case_surgery.west_mrn = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
        batch_pathology_case_surgery.source_system = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['source system']]
        batch_pathology_case_surgery.stable_identifier_path = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
        batch_pathology_case_surgery.stable_identiifer_value = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identiifer value']]
        batch_pathology_case_surgery.case_collect_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['case collect datetime']]
        batch_pathology_case_surgery.accessioned_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
        batch_pathology_case_surgery.accession_nbr_formatted = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
        batch_pathology_case_surgery.group_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group name']]
        batch_pathology_case_surgery.group_desc = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group desc']]
        batch_pathology_case_surgery.group_id = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group id']]
        batch_pathology_case_surgery.snomed_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
        batch_pathology_case_surgery.snomed_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed name']]
        batch_pathology_case_surgery.responsible_pathologist_full_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]
        batch_pathology_case_surgery.responsible_pathologist_npi = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']]
        batch_pathology_case_surgery.section_description = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
        # batch_pathology_report_section.note_text
        batch_pathology_case_surgery.surgical_case_number = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]
        batch_pathology_case_surgery.surgery_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]
        batch_pathology_case_surgery.surgery_start_date = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery start date']]
        batch_pathology_case_surgery.code_type = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['code type']]
        batch_pathology_case_surgery.cpt_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
        batch_pathology_case_surgery.cpt_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt name']]
        batch_pathology_case_surgery.primary_surgeon_full_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]
        batch_pathology_case_surgery.primary_surgeon_npi = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']]

        batch_pathology_case_surgery.save!

        puts 'row'
        puts i
        puts 'west mrn'
        west_mrn = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
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

        provider = Provider.where(provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]).first
        if provider.blank?
          provider_id = Provider.maximum(:provider_id)
          if provider_id.nil?
            provider_id = 1
          else
            provider_id+=1
          end
          provider = Provider.new(provider_id: provider_id, provider_name: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], npi: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
          provider.save!
        end

        accession_nbr_formatted = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
        puts 'accession_nbr_formatted'
        puts accession_nbr_formatted
        accessioned_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
        accessioned_datetime = accessioned_datetime.to_date.to_s
        procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: 'accession nbr formatted', stable_identifier_value_1: accession_nbr_formatted).first
        if procedure_occurrence_stable_identifier.blank?
          puts 'not here yet'
          snomed_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
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

        stable_identifier_path = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
        stable_identifier_value = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identiifer value']]

        note_stable_identifier = NoteStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value: stable_identifier_value)

        if note_stable_identifier.blank?
          note_title = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
          puts 'hello booch'
          puts pathology_procedure_map['section description']
          puts note_title
          note_text = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['note text']]
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

        surgical_case_number = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]

        surgery = false
        if surgical_case_number.present?
          puts 'here 1'
          stable_identifier_path = 'surgical case number'
          stable_identifier_value_1 = surgical_case_number
          procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_path: stable_identifier_path, stable_identifier_value_1: surgical_case_number).first
          surgery = true
        end

        if surgery && procedure_occurrence_stable_identifier.blank?
          cpt = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
          surgery_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]

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

          provider = Provider.where(provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]).first
          if provider.blank?
            provider_id = Provider.maximum(:provider_id)
            if provider_id.nil?
              provider_id = 1
            else
              provider_id+=1
            end
            provider = Provider.new(provider_id: provider_id, provider_name: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], npi: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']], dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept_id, provider_source_value: pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']], specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil)
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

  desc "Normalize accession numbers"
  task(normalize_accession_numbers: :environment) do  |t, args|
    CaseNumber.delete_all
    case_numbers_from_file = CSV.new(File.open('lib/setup/data/biorepository_prostate/prostate_spore_case_numbers.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    case_numbers_from_file.each do |case_number_from_file|
      case_number = CaseNumber.new
      case_number.case_number = case_number_from_file['case_number']
      case_number.west_mrn = case_number_from_file['west_mrn']
      case_number.save!
    end

    PathologyAccessionNumber.delete_all
    bsi2_accession_numbers = CSV.new(File.open('lib/setup/data/biorepository_prostate/pspore_inventory_bsi2.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    bsi2_accession_numbers.each do |bsi2_accession_number|
      pathology_accession_number = PathologyAccessionNumber.new
      pathology_accession_number.case_number = bsi2_accession_number['case_number']
      pathology_accession_number.specimen_identifier = bsi2_accession_number['specimen_identifier']
      pathology_accession_number.specimen_type = bsi2_accession_number['specimen_type']

      specimen_type_normalized = case bsi2_accession_number['specimen_type']
      when 'WHOLE BLOOD'
        'Whole Blood'
      when 'urine (unspun)'
        'Urine (unspun)'
      when 'URINE'
        'Urine'
      when 'urine (spun)', 'Spun Urine'
        'Urine (spun)'
      when 'SPUN URINE'
        'Spun Urine'
      when 'prostatic fluid'
        'Prostatic Fluid'
      when 'FROZEN TISSUE'
        'Frozen Tissue'
      when 'dna'
        'DNA'
      when 'Seminal Vesical Fluid', 'seminal vesicle fluid'
        'Seminal Vesicle Fluid'
      else
        bsi2_accession_number['specimen_type']
      end

      pathology_accession_number.specimen_type_normalized = specimen_type_normalized

      pathology_accession_number.collection_date_raw = bsi2_accession_number['collection_date']
      begin
        pathology_accession_number.collection_date = Date.parse(bsi2_accession_number['collection_date'])
      rescue Exception => e
      end

      pathology_accession_number.receive_date_raw = bsi2_accession_number['receive_date']
      begin
        pathology_accession_number.receive_date = Date.parse(bsi2_accession_number['receive_date'])
      rescue Exception => e
      end

      pathology_accession_number.accession_number_raw = bsi2_accession_number['accession_number']
      if bsi2_accession_number['accession_number'].present?
        if bsi2_accession_number['accession_number'].length == 14 || bsi2_accession_number['accession_number'].length == 15
          accession_number_normalized = bsi2_accession_number['accession_number']
          pathology_accession_number.accession_number_normalized = accession_number_normalized
        end

        case bsi2_accession_number['accession_number'][0..5]
        when '1-S-14', '1-S-15'
          puts 'here we are'
          puts bsi2_accession_number['accession_number'][7..13]
          token = bsi2_accession_number['accession_number'][7..13]
          puts 'here is the token'
          puts token
          token = token.rjust(7, '0')
          puts 'here is the padded token'
          puts token
          accession_number_normalized = bsi2_accession_number['accession_number'][0..5] + '-' + token
          puts 'here is the normalized accession number 1'
          puts accession_number_normalized
          pathology_accession_number.accession_number_normalized = accession_number_normalized
        end

        case bsi2_accession_number['accession_number'][0..2]
        when  'S14', 'S15', 'S16', 'S17', 'S18', 'S19', 'S20', 'S21'
          token = bsi2_accession_number['accession_number'][4..10]
          token = token.rjust(7, '0')
          accession_number_normalized = '1-' + bsi2_accession_number['accession_number'][0..2].insert(1,'-') + '-' + token
          puts 'here is the normalized accession number 2'
          puts accession_number_normalized
          pathology_accession_number.accession_number_normalized = accession_number_normalized
        when 'S03', 'S04', 'S05', 'S06'
          token = bsi2_accession_number['accession_number'][4..10]
          token = token.rjust(7, '0')
          accession_number_normalized = '0-' + bsi2_accession_number['accession_number'][0..2].insert(1,'-') + '-' + token
          puts 'here is the normalized accession number 2'
          puts accession_number_normalized
          pathology_accession_number.accession_number_normalized = accession_number_normalized
        end
      end

      procedure_occurrence_stable_identifier = ProcedureOccurrenceStableIdentifier.where(stable_identifier_value_1: accession_number_normalized).first
      case_number = CaseNumber.where(case_number: bsi2_accession_number['case_number']).first
      if case_number
        pathology_accession_number.case_number_found = true
      else
        pathology_accession_number.case_number_found = false
      end
      if procedure_occurrence_stable_identifier.present?
        pathology_accession_number.accession_number_found = true
        if case_number
          person = Person.where(person_id: procedure_occurrence_stable_identifier.procedure_occurrence.person_id).first

          if person.person_source_value == case_number.west_mrn
            pathology_accession_number.accession_number_case_number_found = true
          else
            pathology_accession_number.accession_number_case_number_found = false
          end
        else
          pathology_accession_number.accession_number_case_number_found = false
        end
      else
        pathology_accession_number.accession_number_found = false
        pathology_accession_number.accession_number_case_number_found = false
      end
      pathology_accession_number.save!
    end
  end

  # bundle exec rake biorepository_prostate:gold_standard_to_omop_abstractor_nlp
  desc "Compare gold standard to to OMOP Abstractor NLP"
  task(gold_standard_to_omop_abstractor_nlp: :environment) do  |t, args|
    ComparePsporeSurgery.delete_all
    pspore_surgeries = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/prostate_spore_surgeries.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    pspore_surgeries.each do |pspore_surgery|
      compare_pspore_surgery = ComparePsporeSurgery.new
      compare_pspore_surgery.record_id = pspore_surgery['record_id']
      compare_pspore_surgery.pop_id = pspore_surgery['pop_id']
      compare_pspore_surgery.case_number = pspore_surgery['case_number']
      compare_pspore_surgery.nmhc_mrn = pspore_surgery['nmhc_mrn']
      compare_pspore_surgery.diagnosis = pspore_surgery['diagnosis']
      compare_pspore_surgery.affiliate = pspore_surgery['affiliate']
      compare_pspore_surgery.registration_date = Date.parse(pspore_surgery['registration_date']) unless pspore_surgery['registration_date'].blank?
      compare_pspore_surgery.consent_date = Date.parse(pspore_surgery['consent_date']) unless pspore_surgery['consent_date'].blank?
      compare_pspore_surgery.surgery_date = Date.parse(pspore_surgery['surgery_date']).to_s unless pspore_surgery['surgery_date'].blank?
      compare_pspore_surgery.surgery_type = pspore_surgery['surgery_type']
      compare_pspore_surgery.pathological_staging_t = map_pathological_staging_t(pspore_surgery['pathological_staging_t'])
      compare_pspore_surgery.pathological_staging_n = pspore_surgery['pathological_staging_n']
      compare_pspore_surgery.pathological_staging_m = pspore_surgery['pathological_staging_m']
      compare_pspore_surgery.surgery_prostate_weight = pspore_surgery['surgery_prostate_weight']
      compare_pspore_surgery.nervesparing_procedure = pspore_surgery['nervesparing_procedure']
      compare_pspore_surgery.extra_capsular_extension = pspore_surgery['extra_capsular_extension']
      compare_pspore_surgery.margins = pspore_surgery['margins']
      compare_pspore_surgery.seminal_vesicle = pspore_surgery['seminal_vesicle']
      compare_pspore_surgery.lymph_nodes = pspore_surgery['lymph_nodes']
      compare_pspore_surgery.lymphatic_vascular_invasion = pspore_surgery['lymphatic_vascular_invasion']
      compare_pspore_surgery.surgery_perineural = pspore_surgery['surgery_perineural']
      compare_pspore_surgery.surgery_gleason_1 = pspore_surgery['surgery_gleason_1']
      compare_pspore_surgery.surgery_gleason_2 = pspore_surgery['surgery_gleason_2']
      compare_pspore_surgery.surgery_gleason_tertiary = pspore_surgery['surgery_gleason_tertiary']
      compare_pspore_surgery.surgery_precentage_of_prostate_cancer_tissue = pspore_surgery['surgery_precentage_of_prostate_cancer_tissue']
      compare_pspore_surgery.save!
    end

    # surgery_map={}
    # surgery_map['Cystoscopy Prostate Coagulation/Vaporization/En...'] = 'Cystoprostatectomy'
    # surgery_map['Cystoscopy Prostate Transurethral Incision'] =  'Cystoprostatectomy'
    # surgery_map['Cystoscopy Prostate Transurethral Resection TURP'] = 'Cystoprostatectomy'
    # surgery_map['LAPAROSCOPIC PROSTATECTOMY'] = 'LapRRP'
    # surgery_map['PROSTATE LASER ENUCLEATION'] =  'LaserProstatectomy'
    # surgery_map['PROSTATE LASER ENUCLEATION LARGE']  = 'LaserProstatectomy'
    # surgery_map['PROSTATE NEEDLE BIOPSY, TRANS RECTAL, (CALL U/S...'] =  'TURP'
    # surgery_map['Prostatectomy Radical Ileal Conduit Creation Ly...'] =  'RadicalRetropubicProstatectomy'
    # surgery_map['Prostatectomy Radical Perineal']  = 'RadicalPerinealProstatectomy'
    # surgery_map['Prostatectomy Radical Retropubic'] =  'RadicalRetropubicProstatectomy'
    # surgery_map['Prostatectomy Radical Retropubic Laparoscopy Ro...']  = 'LapRRP'
    # surgery_map['Prostatectomy Radical Retropubic Lymphadenectomy'] =  'RadicalRetropubicProstatectomy'
    # surgery_map['Prostatectomy Subtotal Perineal']= 'RadicalPerinealProstatectomy'
    # surgery_map['SI ROBOTIC RADICAL PROSTATECTOMY'] =  'RadicalRetropubicProstatectomy'
    # surgery_map['XI ROBOTIC RADICAL PROSTATECTOMY']  = 'RadicalRetropubicProstatectomy'
    # surgery_map['zzCystoscopy, w/Resection, Prostate, Transureth...']= 'TURP'
    # surgery_map['ZZZ XI ROBOTIC RADICAL PROSTATECTOMY'] = 'RadicalRetropubicProstatectomy'
    # surgery_map['zzzProstatectomy Laparoscopic DaVinci (Prentice)'] =  'LapRRP'
    # surgery_map['zzzProstatectomy Radical'] = 'RadicalRetropubicProstatectomy'
    # surgery_map['zzzProstatectomy Radical (Prentice)'] = 'RadicalRetropubicProstatectomy'
    # surgery_map['zzzProstatectomy Radical Laparoscopic'] =  'LapRRP'

    surgery_map={}
    surgery_map['cystoscopy prostate coagulation/vaporization/en...'] = 'Cystoprostatectomy'
    surgery_map['cystoscopy prostate transurethral incision'] =	'Cystoprostatectomy'
    surgery_map['cystoscopy prostate transurethral resection turp'] = 'Cystoprostatectomy'
    surgery_map['laparoscopic prostatectomy'] = 'LapRRP'
    surgery_map['prostate laser enucleation'] =	'LaserProstatectomy'
    surgery_map['prostate laser enucleation large']	= 'LaserProstatectomy'
    surgery_map['prostate needle biopsy, trans rectal, (call u/s...'] =	'TURP'
    surgery_map['prostatectomy radical ileal conduit creation ly...'] =	'RadicalRetropubicProstatectomy'
    surgery_map['prostatectomy radical perineal']	= 'RadicalPerinealProstatectomy'
    surgery_map['prostatectomy radical retropubic'] =	'RadicalRetropubicProstatectomy'
    surgery_map['prostatectomy radical retropubic laparoscopy ro...']	= 'LapRRP'
    surgery_map['prostatectomy radical retropubic lymphadenectomy'] =	'RadicalRetropubicProstatectomy'
    surgery_map['prostatectomy subtotal perineal']= 'RadicalPerinealProstatectomy'
    surgery_map['si robotic radical prostatectomy'] =	'RadicalRetropubicProstatectomy'
    surgery_map['xi robotic radical prostatectomy']	= 'RadicalRetropubicProstatectomy'
    surgery_map['zzcystoscopy, w/resection, prostate, transureth...']= 'TURP'
    surgery_map['zzz xi robotic radical prostatectomy'] = 'RadicalRetropubicProstatectomy'
    surgery_map['zzzprostatectomy laparoscopic davinci (prentice)'] =	'LapRRP'
    surgery_map['zzzprostatectomy radical'] = 'RadicalRetropubicProstatectomy'
    surgery_map['zzzprostatectomy radical (prentice)'] = 'RadicalRetropubicProstatectomy'
    surgery_map['zzzprostatectomy radical laparoscopic'] =	'LapRRP'
    surgery_map['prostatectomy radical retropubic laparoscopy robotic'] = 'RadicalRetropubicProstatectomy'
    surgery_map['cystectomy complete ileal conduit'] = 'Cystoprostatectomy'

    pspore_abstractor_surgeries = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/prostate_spore_surgeries_omop_abstractor.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    pspore_abstractor_surgeries_by_nmhc_mrn = {}
    pspore_abstractor_surgeries.each do |pspore_abstractor_surgery|
      if pspore_abstractor_surgeries_by_nmhc_mrn[pspore_abstractor_surgery['person_source_value']].blank?
        pspore_abstractor_surgeries_by_nmhc_mrn[pspore_abstractor_surgery['person_source_value']] = []
      end
      pspore_abstractor_surgeries_by_nmhc_mrn[pspore_abstractor_surgery['person_source_value']] << { note_title: pspore_abstractor_surgery['note_title'], procedure_date: pspore_abstractor_surgery['procedure_date'] }
    end
    pspore_abstractor_surgeries = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/prostate_spore_surgeries_omop_abstractor.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    pspore_abstractor_surgeries.each do |pspore_abstractor_surgery|
      if pspore_abstractor_surgery['abstractor_namespace_name'] == 'Surgical Pathology'
        puts pspore_abstractor_surgery['person_source_value']
        surgery_type_abstractor = surgery_map[pspore_abstractor_surgery['surgery_procedure_source_value'].try(:downcase)]
        compare_pspore_surgery = ComparePsporeSurgery.where(nmhc_mrn: pspore_abstractor_surgery['person_source_value']).first
        puts 'found surgery?'
        puts compare_pspore_surgery.present?
        puts 'found surgery type mapping?'
        puts surgery_type_abstractor.present?
        puts 'surgery_procedure_source_value'
        puts pspore_abstractor_surgery['surgery_procedure_source_value'].try(:downcase)
        if surgery_type_abstractor.present? && compare_pspore_surgery.present? && pspore_abstractor_surgery['has_cancer_site']!= 'not applicable'
          # if pspore_abstractor_surgery['note_title'] == 'Synoptic Reports' || (pspore_abstractor_surgery['note_title'] != 'Synoptic Reports' && !pspore_abstractor_surgeries_by_nmhc_mrn[pspore_abstractor_surgery['person_source_value']].include?({ note_title: 'Synoptic Reports', procedure_date: pspore_abstractor_surgery['procedure_date'] }))
          if pspore_abstractor_surgery['note_title'] != 'Synoptic Reports'
            puts 'we made it'
            puts pspore_abstractor_surgery['note_title']
            compare_pspore_surgery.surgery_type_abstractor = surgery_type_abstractor
            compare_pspore_surgery.diagnosis_abstractor = pspore_abstractor_surgery['has_cancer_histology'] || pspore_abstractor_surgery['has_cancer_histology_suggestions']
            compare_pspore_surgery.surgery_date_abstractor = pspore_abstractor_surgery['surgery_procedure_date']
            compare_pspore_surgery.pathological_staging_t_abstractor = pspore_abstractor_surgery['pathological_tumor_staging_category']
            compare_pspore_surgery.pathological_staging_n_abstractor = map_pathological_staging_n(pspore_abstractor_surgery['pathological_nodes_staging_category'])
            compare_pspore_surgery.pathological_staging_m_abstractor = map_pathological_staging_m(pspore_abstractor_surgery['pathological_metastasis_staging_category'])
            compare_pspore_surgery.surgery_prostate_weight_abstractor = normalize_has_prostate_weight(pspore_abstractor_surgery['has_prostate_weight'])
            compare_pspore_surgery.extra_capsular_extension_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_extraprostatic_extension'])
            compare_pspore_surgery.margins_abstractor = map_positive_or_negative(pspore_abstractor_surgery['has_margin_status'])
            compare_pspore_surgery.seminal_vesicle_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_seminal_vesicle_invasion'])
            compare_pspore_surgery.lymph_nodes_abstractor = map_has_lymph_nodes_positive_tumor_to_lymph_nodes(pspore_abstractor_surgery['has_number_lymph_nodes_positive_tumor'])
            compare_pspore_surgery.lymphatic_vascular_invasion_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_lymphovascular_invasion'])
            compare_pspore_surgery.surgery_perineural_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_perineural_invasion'])
            compare_pspore_surgery.surgery_gleason_1_abstractor = map_has_gleason_score_grade_to_surgery_gleason_1(pspore_abstractor_surgery['has_gleason_score_grade'])
            compare_pspore_surgery.surgery_gleason_2_abstractor = map_has_gleason_score_grade_to_surgery_gleason_2(pspore_abstractor_surgery['has_gleason_score_grade'])
            compare_pspore_surgery.surgery_precentage_of_prostate_cancer_tissue_abstractor = nil
            compare_pspore_surgery.accession_number = pspore_abstractor_surgery['procedure_occurrence_stable_identifier_value']
            compare_pspore_surgery.save!
          end
        end

        if surgery_type_abstractor.present? && compare_pspore_surgery.present? && pspore_abstractor_surgery['note_title'] == 'Synoptic Reports'
          puts 'we made it to synoptic'
          puts pspore_abstractor_surgery['note_title']
          compare_pspore_surgery.pathological_staging_t_abstractor = pspore_abstractor_surgery['pathological_tumor_staging_category'] if not_set?(compare_pspore_surgery.pathological_staging_t_abstractor)
          compare_pspore_surgery.pathological_staging_n_abstractor = map_pathological_staging_n(pspore_abstractor_surgery['pathological_nodes_staging_category']) if not_set?(compare_pspore_surgery.pathological_staging_n_abstractor)
          compare_pspore_surgery.pathological_staging_m_abstractor = map_pathological_staging_m(pspore_abstractor_surgery['pathological_metastasis_staging_category']) if not_set?(compare_pspore_surgery.pathological_staging_m_abstractor)
          compare_pspore_surgery.surgery_prostate_weight_abstractor = normalize_has_prostate_weight(pspore_abstractor_surgery['has_prostate_weight']) if not_set?(compare_pspore_surgery.surgery_prostate_weight_abstractor)
          compare_pspore_surgery.extra_capsular_extension_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_extraprostatic_extension']) if not_set?(compare_pspore_surgery.extra_capsular_extension_abstractor)
          compare_pspore_surgery.margins_abstractor = map_positive_or_negative(pspore_abstractor_surgery['has_margin_status']) if not_set?(compare_pspore_surgery.margins_abstractor)
          compare_pspore_surgery.seminal_vesicle_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_seminal_vesicle_invasion']) if not_set?(compare_pspore_surgery.seminal_vesicle_abstractor)
          compare_pspore_surgery.lymph_nodes_abstractor = map_has_lymph_nodes_positive_tumor_to_lymph_nodes(pspore_abstractor_surgery['has_number_lymph_nodes_positive_tumor']) if not_set?(compare_pspore_surgery.lymph_nodes_abstractor)
          compare_pspore_surgery.lymphatic_vascular_invasion_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_lymphovascular_invasion']) if not_set?(compare_pspore_surgery.lymphatic_vascular_invasion_abstractor)
          compare_pspore_surgery.surgery_perineural_abstractor = map_present_or_not_identified(pspore_abstractor_surgery['has_perineural_invasion']) if not_set?(compare_pspore_surgery.surgery_perineural_abstractor)
          compare_pspore_surgery.surgery_gleason_1_abstractor = map_has_gleason_score_grade_to_surgery_gleason_1(pspore_abstractor_surgery['has_gleason_score_grade']) if not_set?(compare_pspore_surgery.surgery_gleason_1_abstractor)
          compare_pspore_surgery.surgery_gleason_2_abstractor = map_has_gleason_score_grade_to_surgery_gleason_2(pspore_abstractor_surgery['has_gleason_score_grade']) if not_set?(compare_pspore_surgery.surgery_gleason_2_abstractor)
          compare_pspore_surgery.surgery_precentage_of_prostate_cancer_tissue_abstractor = nil
          compare_pspore_surgery.accession_number = pspore_abstractor_surgery['procedure_occurrence_stable_identifier_value']
          compare_pspore_surgery.save!
        end
      end
    end
  end

  # bundle exec rake biorepository_prostate:update_redcap_surgeries
  desc "Update REDCap surgeries"
  task(update_redcap_surgeries: :environment) do  |t, args|
    redcap_api = RedcapApi.new()
    response = redcap_api.patients
    patients = response[:response]

    pspore_surgeries = ComparePsporeSurgery.where("surgery_date IS NULL AND surgery_date_abstractor IS NOT NULL AND diagnosis IS NULL AND surgery_type IS NULL").all
    pspore_surgeries.each do |pspore_surgery|
      patient = patients.detect{ |patient| patient['case_number'] ==  pspore_surgery.case_number }
      if patient
        puts 'Found the patient!'
        puts patient['case_number']

        redcap_api.update_surgery(patient['record_id'], map_diagnosis(pspore_surgery.diagnosis_abstractor), pspore_surgery.surgery_date_abstractor, pspore_surgery.surgery_type_abstractor, pspore_surgery.accession_number, map_pathological_staging_t_abstractor(pspore_surgery.pathological_staging_t_abstractor), pspore_surgery.pathological_staging_n_abstractor, pspore_surgery.pathological_staging_m_abstractor, pspore_surgery.surgery_prostate_weight_abstractor, pspore_surgery.nervesparing_procedure, pspore_surgery.extra_capsular_extension_abstractor, pspore_surgery.margins_abstractor, pspore_surgery.seminal_vesicle_abstractor, pspore_surgery.lymph_nodes_abstractor, pspore_surgery.lymphatic_vascular_invasion_abstractor, pspore_surgery.surgery_perineural_abstractor, pspore_surgery.surgery_gleason_1_abstractor, pspore_surgery.surgery_gleason_2_abstractor, pspore_surgery.surgery_gleason_tertiary, pspore_surgery.surgery_precentage_of_prostate_cancer_tissue_abstractor)
      else
        puts 'Where is the patient?'
      end
    end
  end

  # # require 'csv'
  # # require 'redcap_api'
  # # bundle exec rake biorepository_prostate:update_redcap_surgeries
  # desc "Update REDCap biopsies"
  # task(update_redcap_biopsies: :environment) do  |t, args|
  #   redcap_api = RedcapApi.new('prostate_spore')
  #   response = redcap_api.patients
  #   patients = response[:response]
  #   prostate_biopsies = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/prostate_abstractor_biopsies.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
  #
  #   nmhc_mrns = ['?']
  #
  #   prostate_biopsies = prostate_biopsies.select { |prostate_biopsy| prostate_biopsy['has_prostate_biopsy'] == 'prostate gland (c61.9)' && (prostate_biopsy['has_cancer_histology'] || prostate_biopsy['has_cancer_histology_suggestions'].present?) &&  nmhc_mrns.include?(prostate_biopsy['person_source_value'])}
  #   prostate_biopsies = prostate_biopsies.group_by{ |prostate_biopsy| prostate_biopsy['procedure_occurrence_stable_identifier_value'] }
  #
  #   # { record_id: nil , biopsy_date: nil, biopsy_reported_by: nil, biopsy_result: nil, biopsy_total_cores: nil, biopsy_positive_cores: nil , biopsy_gleason_1: nil, biopsy_gleason_2: nil, biopsy_gleason_tertiary: nil,  biopsy_involving_percentage_of_prostate_tissue: nil, biopsy_perineural_invasion: nil, biopsies_complete: nil }
  #   prostate_biopsies_to_redcap = []
  #   prostate_biopsies.each_pair do |key, value|
  #     prostate_biopsy_to_redcap = new_prostate_biopsy_to_redcap
  #     biopsy_total_cores = nil
  #     biopsy_positive_cores = nil
  #     has_gleason_score_grade_serverity_new = nil
  #     has_gleason_score_grade_serverity = nil
  #     has_gleason_score_grade = nil
  #
  #     value.each do |prostate_biopsy_specimen|
  #       patient = patients.detect{ |patient| patient['nmhc_mrn'] ==  prostate_biopsy_specimen['person_source_value']  }
  #       puts 'look at me?'
  #       if patient
  #         puts 'ok i will'
  #         prostate_biopsy_to_redcap[:record_id] = patient['record_id']
  #         prostate_biopsy_to_redcap[:biopsy_pathology_number] = prostate_biopsy_specimen['procedure_occurrence_stable_identifier_value']
  #         prostate_biopsy_to_redcap[:biopsy_date] = prostate_biopsy_specimen['procedure_date']
  #         prostate_biopsy_to_redcap[:biopsy_reported_by] = 'M' #Medical Personnel
  #         prostate_biopsy_to_redcap[:biopsy_result] = 'C' #Cancer
  #
  #         positive_cores_of_cores = map_has_positive_cores_of_cores_to_numeric(prostate_biopsy_specimen['has_positive_cores_of_cores'])
  #         puts 'moomin time'
  #         puts positive_cores_of_cores
  #         if positive_cores_of_cores.present?
  #           if biopsy_total_cores
  #             biopsy_total_cores+= positive_cores_of_cores[:cores]
  #           else
  #             biopsy_total_cores = positive_cores_of_cores[:cores]
  #           end
  #           if biopsy_positive_cores
  #             biopsy_positive_cores+= positive_cores_of_cores[:positive_cores]
  #           else
  #             biopsy_positive_cores = positive_cores_of_cores[:positive_cores]
  #           end
  #         end
  #         prostate_biopsy_to_redcap[:biopsy_total_cores] = biopsy_total_cores
  #         prostate_biopsy_to_redcap[:biopsy_positive_cores] = biopsy_positive_cores
  #         has_gleason_score_grade_serverity_new = map_has_gleason_score_grade_to_serverity(prostate_biopsy_specimen['has_gleason_score_grade'])
  #         if has_gleason_score_grade_serverity_new.present?
  #           if has_gleason_score_grade_serverity.present?
  #             if has_gleason_score_grade_serverity_new > has_gleason_score_grade_serverity
  #               has_gleason_score_grade_serverity = has_gleason_score_grade_serverity_new
  #               has_gleason_score_grade = prostate_biopsy_specimen['has_gleason_score_grade']
  #               mapped_has_gleason_score_grade = map_has_gleason_score_grade(prostate_biopsy_specimen['has_gleason_score_grade'])
  #               prostate_biopsy_to_redcap[:biopsy_gleason_1] = mapped_has_gleason_score_grade[:gleason_1]
  #               prostate_biopsy_to_redcap[:biopsy_gleason_2] = mapped_has_gleason_score_grade[:gleason_2]
  #             end
  #           else
  #             has_gleason_score_grade_serverity = has_gleason_score_grade_serverity_new
  #             has_gleason_score_grade = prostate_biopsy_specimen['has_gleason_score_grade']
  #             mapped_has_gleason_score_grade = map_has_gleason_score_grade(prostate_biopsy_specimen['has_gleason_score_grade'])
  #             prostate_biopsy_to_redcap[:biopsy_gleason_1] = mapped_has_gleason_score_grade[:gleason_1]
  #             prostate_biopsy_to_redcap[:biopsy_gleason_2] = mapped_has_gleason_score_grade[:gleason_2]
  #           end
  #         end
  #         prostate_biopsy_to_redcap[:biopsies_complete] = '1'
  #       end
  #     end
  #     prostate_biopsies_to_redcap << prostate_biopsy_to_redcap
  #   end
  #   prostate_biopsies_to_redcap.each do |prostate_biopsy_to_redcap|
  #     puts 'what the hell?'
  #     puts prostate_biopsy_to_redcap
  #     puts prostate_biopsy_to_redcap[:record_id]
  #     response = redcap_api.prostate_spore_biopsies(prostate_biopsy_to_redcap[:record_id])
  #     redcap_repeat_instance = response[:redcap_repeat_instance]
  #
  #     redcap_api.update_prostate_spore_biopsy(prostate_biopsy_to_redcap[:record_id], redcap_repeat_instance, prostate_biopsy_to_redcap[:biopsy_pathology_number], prostate_biopsy_to_redcap[:biopsy_date], prostate_biopsy_to_redcap[:biopsy_reported_by], prostate_biopsy_to_redcap[:biopsy_result], prostate_biopsy_to_redcap[:biopsy_total_cores], prostate_biopsy_to_redcap[:biopsy_positive_cores], prostate_biopsy_to_redcap[:biopsy_gleason_1], prostate_biopsy_to_redcap[:biopsy_gleason_2], nil, nil, nil, prostate_biopsy_to_redcap[:biopsies_complete])
  #   end
  # end
  #

  # require 'csv'
  # require 'redcap_api'
  # bundle exec rake biorepository_prostate:update_redcap_biopsies
  desc "Update REDCap biopsies"
  task(update_redcap_biopsies: :environment) do  |t, args|
    redcap_api = RedcapApi.new('prostate_spore')
    response = redcap_api.patients
    patients = response[:response]
    prostate_biopsies = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/prostate_abstractor_biopsies.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    nmhc_mrns = ['?']

    prostate_biopsies = prostate_biopsies.select { |prostate_biopsy| prostate_biopsy['has_prostate_biopsy'] == 'prostate gland (c61.9)' && (prostate_biopsy['has_cancer_histology'] || prostate_biopsy['has_cancer_histology_suggestions'].present?) &&  nmhc_mrns.include?(prostate_biopsy['person_source_value'])}
    prostate_biopsies = prostate_biopsies.group_by{ |prostate_biopsy| prostate_biopsy['procedure_occurrence_stable_identifier_value'] }

    # { record_id: nil , biopsy_date: nil, biopsy_reported_by: nil, biopsy_result: nil, biopsy_total_cores: nil, biopsy_positive_cores: nil , biopsy_gleason_1: nil, biopsy_gleason_2: nil, biopsy_gleason_tertiary: nil,  biopsy_involving_percentage_of_prostate_tissue: nil, biopsy_perineural_invasion: nil, biopsies_complete: nil }
    prostate_biopsies_to_redcap = []
    prostate_biopsies.each_pair do |key, value|
      prostate_biopsy_to_redcap = new_prostate_biopsy_to_redcap
      biopsy_total_cores = nil
      biopsy_positive_cores = nil
      has_gleason_score_grade_serverity_new = nil
      has_gleason_score_grade_serverity = nil
      has_gleason_score_grade = nil

      value.each do |prostate_biopsy_specimen|
        patient = patients.detect{ |patient| patient['nmhc_mrn'] ==  prostate_biopsy_specimen['person_source_value']  }
        puts 'look at me?'
        if patient
          puts 'ok i will'
          puts 'nmhc_mrn'
          puts patient['nmhc_mrn']
          prostate_biopsy_to_redcap[:record_id] = patient['record_id']
          prostate_biopsy_to_redcap[:biopsy_pathology_number] = prostate_biopsy_specimen['procedure_occurrence_stable_identifier_value']
          if prostate_biopsy_specimen['has_surgery_date']
            prostate_biopsy_to_redcap[:biopsy_date] = prostate_biopsy_specimen['has_surgery_date'] unless prostate_biopsy_specimen['has_surgery_date'] == 'not applicable'
          else
            prostate_biopsy_to_redcap[:biopsy_date] = prostate_biopsy_specimen['procedure_date']
          end

          prostate_biopsy_to_redcap[:biopsy_reported_by] = 'M' #Medical Personnel
          prostate_biopsy_to_redcap[:biopsy_result] = 'C' #Cancer

          positive_cores_of_cores = map_has_positive_cores_of_cores_to_numeric(prostate_biopsy_specimen['has_positive_cores_of_cores'])
          puts 'moomin time'
          puts positive_cores_of_cores
          if positive_cores_of_cores.present?
            if biopsy_total_cores
              biopsy_total_cores+= positive_cores_of_cores[:cores]
            else
              biopsy_total_cores = positive_cores_of_cores[:cores]
            end
            if biopsy_positive_cores
              biopsy_positive_cores+= positive_cores_of_cores[:positive_cores]
            else
              biopsy_positive_cores = positive_cores_of_cores[:positive_cores]
            end
          end

          prostate_biopsy_to_redcap[:biopsy_total_cores] = biopsy_total_cores
          prostate_biopsy_to_redcap[:biopsy_positive_cores] = biopsy_positive_cores
          has_gleason_score_grade_serverity_new = map_has_gleason_score_grade_to_serverity(prostate_biopsy_specimen['has_gleason_score_grade'])
          if has_gleason_score_grade_serverity_new.present?
            if has_gleason_score_grade_serverity.present?
              if has_gleason_score_grade_serverity_new > has_gleason_score_grade_serverity
                has_gleason_score_grade_serverity = has_gleason_score_grade_serverity_new
                has_gleason_score_grade = prostate_biopsy_specimen['has_gleason_score_grade']
                mapped_has_gleason_score_grade = map_has_gleason_score_grade(prostate_biopsy_specimen['has_gleason_score_grade'])
                prostate_biopsy_to_redcap[:biopsy_gleason_1] = mapped_has_gleason_score_grade[:gleason_1]
                prostate_biopsy_to_redcap[:biopsy_gleason_2] = mapped_has_gleason_score_grade[:gleason_2]
              end
            else
              has_gleason_score_grade_serverity = has_gleason_score_grade_serverity_new
              has_gleason_score_grade = prostate_biopsy_specimen['has_gleason_score_grade']
              mapped_has_gleason_score_grade = map_has_gleason_score_grade(prostate_biopsy_specimen['has_gleason_score_grade'])
              prostate_biopsy_to_redcap[:biopsy_gleason_1] = mapped_has_gleason_score_grade[:gleason_1]
              prostate_biopsy_to_redcap[:biopsy_gleason_2] = mapped_has_gleason_score_grade[:gleason_2]
            end
          end

          biopsy_perineural_invasion = map_has_perineural_invasion(prostate_biopsy_specimen['has_perineural_invasion'])

          if biopsy_perineural_invasion == 'Y'
            prostate_biopsy_to_redcap[:biopsy_perineural_invasion] = biopsy_perineural_invasion
          end

          if biopsy_perineural_invasion == 'N' && prostate_biopsy_to_redcap[:biopsy_perineural_invasion] != 'Y'
            prostate_biopsy_to_redcap[:biopsy_perineural_invasion] = biopsy_perineural_invasion
          end

          prostate_biopsy_to_redcap[:biopsies_complete] = '1'
        end
      end
      prostate_biopsies_to_redcap << prostate_biopsy_to_redcap
    end
    prostate_biopsies_to_redcap.each do |prostate_biopsy_to_redcap|
      puts 'what the hell?'
      puts prostate_biopsy_to_redcap
      puts prostate_biopsy_to_redcap[:record_id]
      response = redcap_api.prostate_spore_biopsies(prostate_biopsy_to_redcap[:record_id])
      response = redcap_api.prostate_spore_biopsies(4650)

      redcap_repeat_instance = response[:redcap_repeat_instance]

      redcap_api.update_prostate_spore_biopsy(prostate_biopsy_to_redcap[:record_id], redcap_repeat_instance, prostate_biopsy_to_redcap[:biopsy_pathology_number], prostate_biopsy_to_redcap[:biopsy_date], prostate_biopsy_to_redcap[:biopsy_reported_by], prostate_biopsy_to_redcap[:biopsy_result], prostate_biopsy_to_redcap[:biopsy_total_cores], prostate_biopsy_to_redcap[:biopsy_positive_cores], prostate_biopsy_to_redcap[:biopsy_gleason_1], prostate_biopsy_to_redcap[:biopsy_gleason_2], nil, nil, prostate_biopsy_to_redcap[:biopsy_perineural_invasion], prostate_biopsy_to_redcap[:biopsies_complete])
    end
  end

  # bundle exec rake biorepository_prostate:compare
  desc "Compare"
  task(compare: :environment) do  |t, args|
    case_numbers_from_file = CSV.new(File.open('lib/setup/data/biorepository_prostate 2/compare.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    normalized_case_numbers = {}

    case_numbers_from_file.each do |case_number_from_file|
      if case_number_from_file['case_number_will'].present?
        if normalized_case_numbers[case_number_from_file['case_number_will']].blank?
          normalized_case_numbers[case_number_from_file['case_number_will']] = { will: case_number_from_file['case_number_will'], clamp: nil}
        else
          normalized_case_numbers[case_number_from_file['case_number_will']][:will] = case_number_from_file['case_number_will']
        end
      end

      if case_number_from_file['case_number_clamp'].present?
        if normalized_case_numbers[case_number_from_file['case_number_clamp']].blank?
          normalized_case_numbers[case_number_from_file['case_number_clamp']] = { will: nil, clamp: case_number_from_file['case_number_clamp']}
        else
          normalized_case_numbers[case_number_from_file['case_number_clamp']][:clamp] = case_number_from_file['case_number_clamp']
        end
      end
    end

    File.open 'lib/setup/data/biorepository_prostate 2/compare_normalized.csv', 'w' do |f|
      f.print 'case_number_will'
      f.print ','
      f.print 'case_number_clamp'
      f.puts ''
      normalized_case_numbers.keys.sort.each do |key|
        f.print normalized_case_numbers[key][:will]
        f.print ','
        f.print normalized_case_numbers[key][:clamp]
        f.puts ''
      end
    end
  end
end

def map_diagnosis(diagnosis_abstractor)
  mapped_diagnosis = nil
  if diagnosis_abstractor.present?
    mapped_diagnosis = 'CaP'
  end
  mapped_diagnosis
end

def not_set?(value)
  value.blank? || value == 'not applicable'
end

def map_pathological_staging_t(pathological_staging_t)
  mapped_pathological_staging_t = nil
  case pathological_staging_t
  when 'T0'
    mapped_pathological_staging_t = 'not applicable'
  when 'T2'
    mapped_pathological_staging_t = 'pT2'
  when 'T2a'
    mapped_pathological_staging_t = 'pT2a'
  when 'T2b'
    mapped_pathological_staging_t = 'pT2b'
  when 'T2c'
    mapped_pathological_staging_t = 'pT2c'
  when 'T3a'
    mapped_pathological_staging_t = 'pT3a'
  when 'T3b'
    mapped_pathological_staging_t = 'pT3b'
  when 'T3c'
    mapped_pathological_staging_t = 'pT3c'
  when 'T4'
    mapped_pathological_staging_t = 'pT4'
  end
  mapped_pathological_staging_t
end

def map_pathological_staging_t_abstractor(pathological_staging_t_abstractor)
  mapped_pathological_staging_t = nil
  case pathological_staging_t_abstractor
  when 'not applicable'
    mapped_pathological_staging_t = 'T0'
  when 'pT2'
    mapped_pathological_staging_t = 'T2'
  when  'pT2a'
    mapped_pathological_staging_t = 'T2a'
  when  'pT2b'
    mapped_pathological_staging_t = 'T2b'
  when 'pT2c'
    mapped_pathological_staging_t = 'T2c'
  when  'pT3a'
    mapped_pathological_staging_t = 'T3a'
  when 'pT3b'
    mapped_pathological_staging_t = 'T3b'
  when 'pT3c'
    mapped_pathological_staging_t = 'T3c'
  when 'pT4'
    mapped_pathological_staging_t = 'T4'
  end
  mapped_pathological_staging_t
end

def map_pathological_staging_n(pathological_staging_n)
  mapped_pathological_staging_n = nil
  case pathological_staging_n
  when 'pNX'
    mapped_pathological_staging_n = 'NX'
  when 'ypN0', 'pN0'
    mapped_pathological_staging_n = 'N0'
  when 'ypN1', 'pN1'
    mapped_pathological_staging_n = 'N1'
  when 'not applicable'
    mapped_pathological_staging_n = nil
  end
  mapped_pathological_staging_n
end

def map_pathological_staging_m(pathological_staging_m)
  mapped_pathological_staging_m = nil
  case pathological_staging_m
  when 'pMX'
    mapped_pathological_staging_m = 'MX'
  when 'pM0'
    mapped_pathological_staging_m = 'M0'
  when 'pM1'
    mapped_pathological_staging_m = 'M1'
  when 'pM1a'
    mapped_pathological_staging_m = 'M1a'
  when 'pM1b'
    mapped_pathological_staging_m = 'M1b'
  when 'not applicable'
    mapped_pathological_staging_m = nil
  end
  mapped_pathological_staging_m
end

def map_has_gleason_score_grade_to_surgery_gleason_1(has_gleason_score_grade)
  mapped_has_gleason_score_grade = map_has_gleason_score_grade(has_gleason_score_grade)
  mapped_has_gleason_score_grade[:gleason_1]
end

def map_has_gleason_score_grade_to_surgery_gleason_2(has_gleason_score_grade)
  mapped_has_gleason_score_grade = map_has_gleason_score_grade(has_gleason_score_grade)
  mapped_has_gleason_score_grade[:surgery_gleason_2]
end

def map_has_gleason_score_grade(has_gleason_score_grade)
  mapped_has_gleason_score_grade = {}
  mapped_has_gleason_score_grade[:gleason_1] = nil
  mapped_has_gleason_score_grade[:gleason_2] = nil
  case has_gleason_score_grade
  when '3+3'
    mapped_has_gleason_score_grade[:gleason_1] = '3'
    mapped_has_gleason_score_grade[:gleason_2] = '3'
  when '3+4'
    mapped_has_gleason_score_grade[:gleason_1] = '3'
    mapped_has_gleason_score_grade[:gleason_2] = '4'
  when '4+4'
    mapped_has_gleason_score_grade[:gleason_1] = '4'
    mapped_has_gleason_score_grade[:gleason_2] = '4'
  when '4+3'
    mapped_has_gleason_score_grade[:gleason_1] = '4'
    mapped_has_gleason_score_grade[:gleason_2] = '3'
  when '4+5'
    mapped_has_gleason_score_grade[:gleason_1] = '4'
    mapped_has_gleason_score_grade[:gleason_2] = '5'
  when '5+4'
    mapped_has_gleason_score_grade[:gleason_1] = '5'
    mapped_has_gleason_score_grade[:gleason_2] = '4'
  when '5+5'
    mapped_has_gleason_score_grade[:gleason_1] = '5'
    mapped_has_gleason_score_grade[:gleason_2] = '5'
  when '3+5'
    mapped_has_gleason_score_grade[:gleason_1] = '3'
    mapped_has_gleason_score_grade[:gleason_2] = '5'
  when '5+3'
    mapped_has_gleason_score_grade[:gleason_1] = '5'
    mapped_has_gleason_score_grade[:gleason_2] = '3'
  end
  mapped_has_gleason_score_grade
end

def map_present_or_not_identified(finding)
  mapped_finding = nil
  case finding
  when 'not identified'
    mapped_finding = 'N'
  when 'present'
    mapped_finding = 'P'
  end
  mapped_finding
end

def map_positive_or_negative(finding)
  mapped_finding = nil
  case finding
  when 'negative'
    mapped_finding = 'N'
  when 'positive'
    mapped_finding = 'P'
  end
  mapped_finding
end

def map_has_lymph_nodes_positive_tumor_to_lymph_nodes(has_number_lymph_nodes_positive_tumor)
  mapped_lymph_nodes = nil
  begin
    has_number_lymph_nodes_positive_tumor_integer = Integer(has_number_lymph_nodes_positive_tumor)
  rescue Exception => e
    has_number_lymph_nodes_positive_tumor_integer = nil
  end

  if has_number_lymph_nodes_positive_tumor_integer
    if has_number_lymph_nodes_positive_tumor_integer > 0
      mapped_lymph_nodes = 'P'
    else
      mapped_lymph_nodes = 'N'
    end
  end
  mapped_lymph_nodes
end

def normalize_has_prostate_weight(has_prostate_weight)
  if has_prostate_weight[-2..-1] == '.0'
    has_prostate_weight.gsub!(/.0$/,'')
  end
  has_prostate_weight
end

def map_has_gleason_score_grade_to_serverity(has_gleason_score_grade)
  gleason_score_grade_severity_map = {}
  gleason_score_grade_severity_map['3+3'] = 1
  gleason_score_grade_severity_map['3+4'] = 2
  gleason_score_grade_severity_map['3+5'] = 3
  gleason_score_grade_severity_map['4+3'] = 4
  gleason_score_grade_severity_map['4+4'] = 5
  gleason_score_grade_severity_map['4+5'] = 6
  gleason_score_grade_severity_map['5+3'] = 7
  gleason_score_grade_severity_map['5+4'] = 8
  gleason_score_grade_severity_map['5+5'] = 9
  gleason_score_grade_severity_map[has_gleason_score_grade]
end

def map_has_positive_cores_of_cores_to_numeric(has_positive_cores_of_cores)
    has_positive_cores_of_cores_numeric_map = {}
    has_positive_cores_of_cores_numeric_map["0 of 1 cores"] = { positive_cores: 0, cores: 1 }
    has_positive_cores_of_cores_numeric_map["1 of 1 cores"] = { positive_cores: 1, cores: 1 }
    has_positive_cores_of_cores_numeric_map["0 of 2 cores"] = { positive_cores: 0, cores: 2 }
    has_positive_cores_of_cores_numeric_map["1 of 2 cores"] = { positive_cores: 1, cores: 2 }
    has_positive_cores_of_cores_numeric_map["2 of 2 cores"] = { positive_cores: 2, cores: 2 }
    has_positive_cores_of_cores_numeric_map["0 of 3 cores"] = { positive_cores: 0, cores: 3 }
    has_positive_cores_of_cores_numeric_map["1 of 3 cores"] = { positive_cores: 1, cores: 3 }
    has_positive_cores_of_cores_numeric_map["2 of 3 cores"] = { positive_cores: 2, cores: 3 }
    has_positive_cores_of_cores_numeric_map["3 of 3 cores"] = { positive_cores: 3, cores: 3 }
    has_positive_cores_of_cores_numeric_map["0 of 4 cores"] = { positive_cores: 0, cores: 4 }
    has_positive_cores_of_cores_numeric_map["1 of 4 cores"] = { positive_cores: 1, cores: 4 }
    has_positive_cores_of_cores_numeric_map["2 of 4 cores"] = { positive_cores: 2, cores: 4 }
    has_positive_cores_of_cores_numeric_map["3 of 4 cores"] = { positive_cores: 3, cores: 4 }
    has_positive_cores_of_cores_numeric_map["4 of 4 cores"] = { positive_cores: 4, cores: 4 }
    has_positive_cores_of_cores_numeric_map["0 of 5 cores"] = { positive_cores: 0, cores: 5 }
    has_positive_cores_of_cores_numeric_map["1 of 5 cores"] = { positive_cores: 1, cores: 5 }
    has_positive_cores_of_cores_numeric_map["2 of 5 cores"] = { positive_cores: 2, cores: 5 }
    has_positive_cores_of_cores_numeric_map["3 of 5 cores"] = { positive_cores: 3, cores: 5 }
    has_positive_cores_of_cores_numeric_map["4 of 5 cores"] = { positive_cores: 4, cores: 5 }
    has_positive_cores_of_cores_numeric_map["5 of 5 cores"] = { positive_cores: 5, cores: 5 }
    has_positive_cores_of_cores_numeric_map["0 of 6 cores"] = { positive_cores: 0, cores: 6 }
    has_positive_cores_of_cores_numeric_map["1 of 6 cores"] = { positive_cores: 1, cores: 6 }
    has_positive_cores_of_cores_numeric_map["2 of 6 cores"] = { positive_cores: 2, cores: 6 }
    has_positive_cores_of_cores_numeric_map["3 of 6 cores"] = { positive_cores: 3, cores: 6 }
    has_positive_cores_of_cores_numeric_map["4 of 6 cores"] = { positive_cores: 4, cores: 6 }
    has_positive_cores_of_cores_numeric_map["5 of 6 cores"] = { positive_cores: 5, cores: 6 }
    has_positive_cores_of_cores_numeric_map["6 of 6 cores"] = { positive_cores: 6, cores: 6 }
    has_positive_cores_of_cores_numeric_map["0 of 7 cores"] = { positive_cores: 0, cores: 7 }
    has_positive_cores_of_cores_numeric_map["1 of 7 cores"] = { positive_cores: 1, cores: 7 }
    has_positive_cores_of_cores_numeric_map["2 of 7 cores"] = { positive_cores: 2, cores: 7 }
    has_positive_cores_of_cores_numeric_map["3 of 7 cores"] = { positive_cores: 3, cores: 7 }
    has_positive_cores_of_cores_numeric_map["4 of 7 cores"] = { positive_cores: 4, cores: 7 }
    has_positive_cores_of_cores_numeric_map["5 of 7 cores"] = { positive_cores: 5, cores: 7 }
    has_positive_cores_of_cores_numeric_map["6 of 7 cores"] = { positive_cores: 6, cores: 7 }
    has_positive_cores_of_cores_numeric_map["7 of 7 cores"] = { positive_cores: 7, cores: 7 }
    has_positive_cores_of_cores_numeric_map["0 of 8 cores"] = { positive_cores: 0, cores: 8 }
    has_positive_cores_of_cores_numeric_map["1 of 8 cores"] = { positive_cores: 1, cores: 8 }
    has_positive_cores_of_cores_numeric_map["2 of 8 cores"] = { positive_cores: 2, cores: 8 }
    has_positive_cores_of_cores_numeric_map["3 of 8 cores"] = { positive_cores: 3, cores: 8 }
    has_positive_cores_of_cores_numeric_map["4 of 8 cores"] = { positive_cores: 4, cores: 8 }
    has_positive_cores_of_cores_numeric_map["5 of 8 cores"] = { positive_cores: 5, cores: 8 }
    has_positive_cores_of_cores_numeric_map["6 of 8 cores"] = { positive_cores: 6, cores: 8 }
    has_positive_cores_of_cores_numeric_map["7 of 8 cores"] = { positive_cores: 7, cores: 8 }
    has_positive_cores_of_cores_numeric_map["8 of 8 cores"] = { positive_cores: 8, cores: 8 }
    has_positive_cores_of_cores_numeric_map["0 of 9 cores"] = { positive_cores: 0, cores: 9 }
    has_positive_cores_of_cores_numeric_map["1 of 9 cores"] = { positive_cores: 1, cores: 9 }
    has_positive_cores_of_cores_numeric_map["2 of 9 cores"] = { positive_cores: 2, cores: 9 }
    has_positive_cores_of_cores_numeric_map["3 of 9 cores"] = { positive_cores: 3, cores: 9 }
    has_positive_cores_of_cores_numeric_map["4 of 9 cores"] = { positive_cores: 4, cores: 9 }
    has_positive_cores_of_cores_numeric_map["5 of 9 cores"] = { positive_cores: 5, cores: 9 }
    has_positive_cores_of_cores_numeric_map["6 of 9 cores"] = { positive_cores: 6, cores: 9 }
    has_positive_cores_of_cores_numeric_map["7 of 9 cores"] = { positive_cores: 7, cores: 9 }
    has_positive_cores_of_cores_numeric_map["8 of 9 cores"] = { positive_cores: 8, cores: 9 }
    has_positive_cores_of_cores_numeric_map["9 of 9 cores"] = { positive_cores: 9, cores: 9 }
    has_positive_cores_of_cores_numeric_map["0 of 10 cores"] = { positive_cores: 0, cores: 10 }
    has_positive_cores_of_cores_numeric_map["1 of 10 cores"] = { positive_cores: 1, cores: 10 }
    has_positive_cores_of_cores_numeric_map["2 of 10 cores"] = { positive_cores: 2, cores: 10 }
    has_positive_cores_of_cores_numeric_map["3 of 10 cores"] = { positive_cores: 3, cores: 10 }
    has_positive_cores_of_cores_numeric_map["4 of 10 cores"] = { positive_cores: 4, cores: 10 }
    has_positive_cores_of_cores_numeric_map["5 of 10 cores"] = { positive_cores: 5, cores: 10 }
    has_positive_cores_of_cores_numeric_map["6 of 10 cores"] = { positive_cores: 6, cores: 10 }
    has_positive_cores_of_cores_numeric_map["7 of 10 cores"] = { positive_cores: 7, cores: 10 }
    has_positive_cores_of_cores_numeric_map["8 of 10 cores"] = { positive_cores: 8, cores: 10 }
    has_positive_cores_of_cores_numeric_map["9 of 10 cores"] = { positive_cores: 9, cores: 10 }
    has_positive_cores_of_cores_numeric_map["10 of 10 cores"] = { positive_cores: 10, cores: 10 }
    has_positive_cores_of_cores_numeric_map["0 of 11 cores"] = { positive_cores: 0, cores: 11 }
    has_positive_cores_of_cores_numeric_map["1 of 11 cores"] = { positive_cores: 1, cores: 11 }
    has_positive_cores_of_cores_numeric_map["2 of 11 cores"] = { positive_cores: 2, cores: 11 }
    has_positive_cores_of_cores_numeric_map["3 of 11 cores"] = { positive_cores: 3, cores: 11 }
    has_positive_cores_of_cores_numeric_map["4 of 11 cores"] = { positive_cores: 4, cores: 11 }
    has_positive_cores_of_cores_numeric_map["5 of 11 cores"] = { positive_cores: 5, cores: 11 }
    has_positive_cores_of_cores_numeric_map["6 of 11 cores"] = { positive_cores: 6, cores: 11 }
    has_positive_cores_of_cores_numeric_map["7 of 11 cores"] = { positive_cores: 7, cores: 11 }
    has_positive_cores_of_cores_numeric_map["8 of 11 cores"] = { positive_cores: 8, cores: 11 }
    has_positive_cores_of_cores_numeric_map["9 of 11 cores"] = { positive_cores: 9, cores: 11 }
    has_positive_cores_of_cores_numeric_map["10 of 11 cores"] = { positive_cores: 10, cores: 11 }
    has_positive_cores_of_cores_numeric_map["11 of 11 cores"] = { positive_cores: 11, cores: 11 }
    has_positive_cores_of_cores_numeric_map["0 of 12 cores"] = { positive_cores: 0, cores: 12 }
    has_positive_cores_of_cores_numeric_map["1 of 12 cores"] = { positive_cores: 1, cores: 12 }
    has_positive_cores_of_cores_numeric_map["2 of 12 cores"] = { positive_cores: 2, cores: 12 }
    has_positive_cores_of_cores_numeric_map["3 of 12 cores"] = { positive_cores: 3, cores: 12 }
    has_positive_cores_of_cores_numeric_map["4 of 12 cores"] = { positive_cores: 4, cores: 12 }
    has_positive_cores_of_cores_numeric_map["5 of 12 cores"] = { positive_cores: 5, cores: 12 }
    has_positive_cores_of_cores_numeric_map["6 of 12 cores"] = { positive_cores: 6, cores: 12 }
    has_positive_cores_of_cores_numeric_map["7 of 12 cores"] = { positive_cores: 7, cores: 12 }
    has_positive_cores_of_cores_numeric_map["8 of 12 cores"] = { positive_cores: 8, cores: 12 }
    has_positive_cores_of_cores_numeric_map["9 of 12 cores"] = { positive_cores: 9, cores: 12 }
    has_positive_cores_of_cores_numeric_map["10 of 12 cores"] = { positive_cores: 10, cores: 12 }
    has_positive_cores_of_cores_numeric_map["11 of 12 cores"] = { positive_cores: 11, cores: 12 }
    has_positive_cores_of_cores_numeric_map["12 of 12 cores"] = { positive_cores: 12, cores: 12 }
    has_positive_cores_of_cores_numeric_map[has_positive_cores_of_cores]
end

def map_has_perineural_invasion(has_perineuarl_invasion)
  mapped_has_perineuarl_invasion = nil
  case has_perineuarl_invasion
  when 'not applicable', nil
    mapped_has_perineuarl_invasion = 'U'
  when 'present'
    mapped_has_perineuarl_invasion = 'Y'
  when 'not identified'
    mapped_has_perineuarl_invasion = 'N'
  end
  mapped_has_perineuarl_invasion
end

def new_prostate_biopsy_to_redcap
  { record_id: nil, biopsy_pathology_number: nil, biopsy_date: nil, biopsy_reported_by: nil, biopsy_result: nil, biopsy_total_cores: nil, biopsy_positive_cores: nil , biopsy_gleason_1: nil, biopsy_gleason_2: nil, biopsy_gleason_tertiary: nil,  biopsy_involving_percentage_of_prostate_tissue: nil, biopsy_perineural_invasion: nil, biopsies_complete: nil }
end