# 7th
# http://sxc.cancerstaging.org/references-tools/quickreferences/Documents/ProstateLarge.pdf

# 8th
# http://sxc.cancerstaging.org/CSE/Physician/Documents/AJCC_PPT%20-Prostate%20Webinar%20v3.pdf

require './lib/omop_abstractor/setup/setup'
require './lib/tasks/omop_abstractor_clamp_dictionary_exporter'
require 'redcap_api'
namespace :nu_chers do
  #bundle exec rake nu_chers:load_case_numbers
  desc "Load case numbers"
  task(load_case_numbers: :environment) do |t, args|
    case_nums = CSV.new(File.open('lib/setup/data/nu_chers/nu_chers_case_nums.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")    
    case_nums.each do |case_num|
      case_number = CaseNumber.where(case_number: case_num['case_num'])
      if case_number.blank?
        CaseNumber.create!(case_number: case_num['case_num'], west_mrn: case_num['west_mrn'],cohort: 'nu chers')
      end
    end
  end
  
  #bundle exec rake nu_chers:set_site_case_numbers
  desc "Set Site case numbers"
  task(set_site_case_numbers: :environment) do |t, args|
    pathology_cases = CSV.new(File.open('lib/setup/data/nu_chers/nu_chers_surgeries_omop_abstractor.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")        
    pathology_cases.each do |pathology_case|

      if (pathology_case['has_cancer_site'].present? && pathology_case['has_cancer_site'] != 'not applicable' ) || pathology_case['has_cancer_site_suggestions'].present? 
        case_number = CaseNumber.where(west_mrn: pathology_case['person_source_value']).first
        if case_number
          site = pathology_case['has_cancer_site'] || pathology_case['has_cancer_site_suggestions']
          if case_number.site.blank?
            case_number.site = site
          else
            site = "#{case_number.site},#{site}"
            site = site.split(',').uniq.join(',')
            case_number.site = site
          end
          case_number.save!
        end
      end              
    end
  end
  
  #bundle exec rake nu_chers:schemas_omop_abstractor_nlp_nu_chers_final_diagnosis
  desc "Load schemas OMOP Abstractor NLP biorepository NU CHERS 'Final Diagnosis'"
  task(schemas_omop_abstractor_nlp_nu_chers_final_diagnosis: :environment) do |t, args|
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
    # abstractor_section_comment.abstractor_section_name_variants.build(name: 'prostatic cancer staging summary')
    # abstractor_section_comment.abstractor_section_name_variants.build(name: 'PROSTATIC CANCER STAGING SUMMARY')
    abstractor_section_comment.save!
    
    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Conversion Final Diagnosis', 'Final Diagnosis',  'Final Diagnosis Rendered', 'Final Pathologic Diagnosis')").first_or_create

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

    gyne_histologies = Icdo3Histology.by_primary_gyne
    gyne_histologies.each do |histology|
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

    gyne_sites = Icdo3Site.by_primary_gyne
    gyne_sites.each do |site|
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
  end

  #bundle exec rake nu_chers:schemas_omop_abstractor_nlp_nu_chers_final_diagnosis
  desc "Load schemas OMOP Abstractor NLP biorepository NU CHERS 'Synoptic Reports'"
  task(schemas_omop_abstractor_nlp_nu_chers_synoptic: :environment) do |t, args|
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
    
    #Synoptic Pathology
    abstractor_namespace_synoptic_pathology = Abstractor::AbstractorNamespace.where(name: 'Synoptic Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('AP SYNOPTIC REPORTS', 'Synoptic Reports')").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create
  
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'Histologic Type').first_or_create

    gyne_histologies = Icdo3Histology.by_primary_gyne
    gyne_histologies.each do |histology|
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

    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '?').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!
    
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_synoptic_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: false).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'Tumor Site').first_or_create
    
    gyne_sites = Icdo3Site.by_primary_gyne
    gyne_sites.each do |site|
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

    # abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(vocabulary_code: '?').first
    # abstractor_object_value.favor_more_specific = true
    # abstractor_object_value.save!

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_synoptic_pathology.id, anchor: false).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: false).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create
  end

  desc "Truncate stable identifiers"
  task(truncate_stable_identifiers: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier CASCADE;')
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE note_stable_identifier_full CASCADE;')
  end

  #bundle exec rake nu_chers:nu_chers_data
  desc "Load NU Chers data"
  task(nu_chers_data: :environment) do |t, args|
    files = ['lib/setup/data/nu_chers/Pathology Cases with Surgeries V2 1.xlsx']
    @note_type_concept = Concept.note_types.where(concept_name: 'Pathology report').first
    @note_class_concept = Concept.standard.valid.where(concept_name: 'Pathology procedure note').first
    # BatchNuChersPathologyReportSection.delete_all
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
         'primary surgeon npi' => 23,
         'case num' => 24         
         
      }

      pathology_procedures_by_mrn = {}

      location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
      gender_concept_id = Concept.genders.first.concept_id
      race_concept_id = Concept.races.first.concept_id
      ethnicity_concept_id =   Concept.ethnicities.first.concept_id

      for i in 2..pathology_procedures.sheet(0).last_row do
        puts 'another one'
        # batch_nu_chers_pathology_report_section = BatchNuChersPathologyReportSection.new
        # batch_nu_chers_pathology_report_section.west_mrn = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['west mrn']]
        # batch_nu_chers_pathology_report_section.source_system = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['source system']]
        # batch_nu_chers_pathology_report_section.stable_identifier_path = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identifier path']]
        # batch_nu_chers_pathology_report_section.stable_identiifer_value = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['stable identiifer value']]
        # batch_nu_chers_pathology_report_section.case_collect_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['case collect datetime']]
        # batch_nu_chers_pathology_report_section.accessioned_datetime = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accessioned datetime']]
        # batch_nu_chers_pathology_report_section.accession_nbr_formatted = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['accession nbr formatted']]
        # batch_nu_chers_pathology_report_section.group_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group name']]
        # batch_nu_chers_pathology_report_section.group_desc = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group desc']]
        # batch_nu_chers_pathology_report_section.group_id = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['group id']]
        # batch_nu_chers_pathology_report_section.snomed_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed code']]
        # batch_nu_chers_pathology_report_section.snomed_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['snomed name']]
        # batch_nu_chers_pathology_report_section.responsible_pathologist_full_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']]
        # batch_nu_chers_pathology_report_section.responsible_pathologist_npi = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist npi']]
        # batch_nu_chers_pathology_report_section.section_description = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['section description']]
        # batch_nu_chers_pathology_report_section.note_text = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['note text']]
        # batch_nu_chers_pathology_report_section.surgical_case_number = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgical case number']]
        # batch_nu_chers_pathology_report_section.surgery_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery name']]
        # batch_nu_chers_pathology_report_section.surgery_start_date = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['surgery start date']]
        # batch_nu_chers_pathology_report_section.code_type = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['code type']]
        # batch_nu_chers_pathology_report_section.cpt_code = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt code']]
        # batch_nu_chers_pathology_report_section.cpt_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['cpt name']]
        # batch_nu_chers_pathology_report_section.primary_surgeon_full_name = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']]
        # batch_nu_chers_pathology_report_section.primary_surgeon_npi = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon npi']]
        # batch_nu_chers_pathology_report_section.case_num = pathology_procedures.sheet(0).row(i)[pathology_procedure_map['case num']]
        # batch_nu_chers_pathology_report_section.save!
                        
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
        if provider.blank? && pathology_procedures.sheet(0).row(i)[pathology_procedure_map['responsible pathologist full name']].present?
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
          if provider.blank? && pathology_procedures.sheet(0).row(i)[pathology_procedure_map['primary surgeon full name']].present?
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
  
  # bundle exec rake nu_chers:update_redcap_baseline_demographics
  desc "Update REDCap Baseline Demographics"
  task(update_redcap_baseline_demographics: :environment) do  |t, args|
    redcap_api = RedcapApi.new('nu_chers')
    response = redcap_api.patients_nu_chers
    patients = response[:response]

    case_numbers = CaseNumber.where('site IS NOT NULL').all

    case_numbers.each do |case_number|
      patient = patients.detect{ |patient| patient['dem_case_num'] ==  case_number.case_number }
      if patient
        puts 'Found the patient!'
        puts patient['case_number']

        redcap_api.update_nu_chers_baseline_demographics(patient['record_id'], map_nu_chers_disease_site(case_number.site, 'cervix'), map_nu_chers_disease_site(case_number.site, 'endometrium'), map_nu_chers_disease_site(case_number.site, 'ovary'), map_nu_chers_disease_site(case_number.site, 'uterus'), map_nu_chers_disease_site(case_number.site, 'vulva'), map_nu_chers_disease_site(case_number.site, 'vagina'), map_nu_chers_disease_site(case_number.site, 'adnexa'), map_nu_chers_disease_site(case_number.site, 'peritoneal_cavity'), '0')
      else
        puts 'Where is the patient?'
      end      
    end
  end
end

# C54.0  Endometrium
# C54.1  Endometrium
# C54.2  Endometrium
# C54.3  Endometrium
# C53.0  Cervix
# C53.1  Cervix
# C53.9  Cervix
# C57.4  Adnexa
# C48.1  Peritoneal Cavity
# C53.9  Cervix
# C54.9  Uterus
# C55.9  Uterus
# C56.9  Ovary
# C57.0  Ovary
# C52.9  Vagina
# C51.0  Vulva
# C51.1  Vulva
# C51.2  Vulva
# C51.9  Vulva
# C76.3  Vulva

def map_nu_chers_disease_site(site, disease_site)
  mapped_disease_site = '0'
  disease_sites = []
  icdo3_site_redcap_disease_site_map = {}
  icdo3_site_redcap_disease_site_map['c54.0'] = 'endometrium'
  icdo3_site_redcap_disease_site_map['c54.1'] = 'endometrium'
  icdo3_site_redcap_disease_site_map['c54.2'] = 'endometrium'  
  icdo3_site_redcap_disease_site_map['c54.3'] = 'endometrium'  
  icdo3_site_redcap_disease_site_map['c53.0'] = 'cervix'  
  icdo3_site_redcap_disease_site_map['c53.1'] = 'cervix'  
  icdo3_site_redcap_disease_site_map['c53.9'] = 'cervix'  
  # icdo3_site_redcap_disease_site_map['c57.4'] = 'adnexa'
  # icdo3_site_redcap_disease_site_map['c48.1'] = 'peritoneal cavity'
  icdo3_site_redcap_disease_site_map['c54.9'] = 'endometrium'      
  icdo3_site_redcap_disease_site_map['c55.9'] = 'endometrium'      
  icdo3_site_redcap_disease_site_map['c56.9'] = 'ovary'      
  icdo3_site_redcap_disease_site_map['c57.0'] = 'ovary'      
  icdo3_site_redcap_disease_site_map['c52.9'] = 'vagina'      
  icdo3_site_redcap_disease_site_map['c51.0'] = 'vulva'      
  icdo3_site_redcap_disease_site_map['c51.2'] = 'vulva'      
  icdo3_site_redcap_disease_site_map['c51.9'] = 'vulva'        
  icdo3_site_redcap_disease_site_map['c76.3'] = 'vulva'        

  site.split(',').each do |s|
    s.strip!
    icdo3_site = s.match(/c\d*\.\d/).to_s
    disease_sites << icdo3_site_redcap_disease_site_map[icdo3_site]
  end
  disease_sites.uniq!
  
  if disease_sites.include?(disease_site)
    mapped_disease_site = '1'
  end
  mapped_disease_site    
end