require './lib/omop_abstractor/setup/setup'
namespace :spacy do
  desc 'Load schemas CLAMP'
  task(schemas_spacy: :environment) do |t, args|
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
    abstractor_section_type_custom = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_OFFSETS).first
    abstractor_section_specimen = Abstractor::AbstractorSection.where(abstractor_section_type: abstractor_section_type_custom, name: 'SPECIMEN', source_type: NoteStableIdentifier.to_s, source_method: 'note_text', return_note_on_empty_section: true).first_or_create

    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note ON note_stable_identifier.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4213297",
    where_clause: "note.note_title in('Final Diagnosis', 'Final Pathologic Diagnosis') AND note_date >='2018-03-01'").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    primary_cns_histologies = CSV.new(File.open('lib/setup/data/primary_cns_diagnoses.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    primary_cns_histologies.each do |histology|
      name = histology['name'].downcase.gsub(', nos', '').strip
      if histology['icdo3_code'].present?
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology['icdo3_code']})".downcase, vocabulary_code: histology['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: 'ICD-O-3').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology['name'].downcase).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = CSV.new(File.open('lib/setup/data/primary_cns_diagnosis_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      histology_synonyms = histology_synonyms.select { |histology_synonym| histology_synonym['diagnosis_id'] == histology['id'] }
      histology_synonyms.each do |histology_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology_synonym['name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create

    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    sites = CSV.new(File.open('lib/setup/data/icdo3_sites.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = CSV.new(File.open('lib/setup/data/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites = sites.select { |site| primary_cns_sites.include?(site['icdo3_code']) }
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.to_hash['name']} (#{site.to_hash['icdo3_code']})".downcase, vocabulary_code: site.to_hash['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.to_hash['name'].downcase).first_or_create
      site_synonyms = CSV.new(File.open('lib/setup/data/icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms.select { |site_synonym| site.to_hash['icdo3_code'] == site_synonym.to_hash['icdo3_code'] }.each do |site_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site_synonym.to_hash['synonym_name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
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

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin WHO Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_who_grade',
      display_name: 'WHO Grade',
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

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Grade 4', vocabulary_code: 'Grade 4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'Grade IV').first_or_create


    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where( abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End WHO Grade

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'initial', vocabulary_code: 'initial').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'recurrent', vocabulary_code: 'recurrent').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'residual').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'recurrence').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
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

    metastatic_histologies = CSV.new(File.open('lib/setup/data/metastatic_diagnoses.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    metastatic_histologies.each do |histology|
      name = histology['name'].downcase.gsub(', nos', '').strip
      if histology['icdo3_code'].present?
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology['icdo3_code']})".downcase, vocabulary_code: histology['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: 'ICD-O-3').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology['name'].downcase).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value)
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = CSV.new(File.open('lib/setup/data/primary_cns_diagnosis_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      histology_synonyms = histology_synonyms.select { |histology_synonym| histology_synonym['diagnosis_id'] == histology['id'] }
      histology_synonyms.each do |histology_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => histology_synonym['name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #Begin metastatic cancer site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    #keep as create, not first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer site

    #Begin metastatic cancer primary site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_primary_site',
      display_name: 'Primary Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'primary cancer site').first_or_create

    sites = CSV.new(File.open('lib/setup/data/icdo3_sites.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = CSV.new(File.open('lib/setup/data/site_site_categories.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    primary_cns_sites = primary_cns_sites.map { |primary_cns_site| primary_cns_site['icdo3_code'] }
    sites = sites.select { |site| !primary_cns_sites.include?(site['icdo3_code']) }
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{site.to_hash['name']} (#{site.to_hash['icdo3_code']})".downcase, vocabulary_code: site.to_hash['icdo3_code'], vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3').first_or_create
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site.to_hash['name'].downcase).first_or_create
      site_synonyms = CSV.new(File.open('lib/setup/data/icdo3_site_synonyms.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
      site_synonyms.select { |site_synonym| site.to_hash['icdo3_code'] == site_synonym.to_hash['icdo3_code'] }.each do |site_synonym|
        Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => site_synonym.to_hash['synonym_name'].downcase).first_or_create
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer primary site

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    #keep as create, not first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    #keep as create, not first_or_create
    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy', section_required: true).first_or_create
    Abstractor::AbstractorAbstractionSourceSection.where(abstractor_abstraction_source: abstractor_abstraction_source, abstractor_section: abstractor_section_specimen).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End metastatic

    #Begin IDH1 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh1_status',
      display_name: 'IDH1 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh1').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh-1').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh 1').first_or_create

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
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create

    #End IDH1 status

    #Begin IDH2 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh2_status',
      display_name: 'IDH2 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh2').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh-2').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'idh 2').first_or_create

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
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create

    #End IDH2 status

    #Begin 1p status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_1p_status',
      display_name: '1P Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '1P').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'OneP').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '1-P').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'deleted', vocabulary_code: 'deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'del.').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'non-deleted', vocabulary_code: 'non-deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'nondeleted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not deleted').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End 1p status

    #Begin 19q status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_19q_status',
      display_name: '19q Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '19Q').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'NineteenQ').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '19-Q').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'deleted', vocabulary_code: 'deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'del.').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'non-deleted', vocabulary_code: 'non-deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'nondeleted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not deleted').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End 19q status

    #Begin 10q/PTEN status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_10q_PTEN_status',
      display_name: '10q/PTEN Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '10q/PTEN').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'TenqPTEN').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '10qPTEN').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: '10q-PTEN').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'deleted', vocabulary_code: 'deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'del.').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'non-deleted', vocabulary_code: 'non-deleted').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'nondeleted').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'not deleted').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End 10q/PTEN status

    #Begin MGMT promoter methylation status Status status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_mgmt_status',
      display_name: 'MGMT promoter methylation status Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'MGMT').first_or_create

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
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End MGMT promoter methylation status Status

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
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
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
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End p53

    abstractor_namespace_outside_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Outside Surgical Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note ON note_stable_identifier.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    where_clause: "note.note_title IN('Final Diagnosis', 'Final Pathologic Diagnosis') AND note_date >='2018-03-01'").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

    #End primary cancer
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 2).first_or_create

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin surgery date
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_surgery_date',
      display_name: 'Surgery Date',
      abstractor_object_type: date_object_type,
      preferred_name: 'Surgery Date').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End surgery date

    #Begin WHO Grade
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_who_grade',
      display_name: 'WHO Grade',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'grade').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create

    #End WHO Grade

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
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

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #Begin metastatic cancer site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer site

    #Begin metastatic cancer primary site
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_metastatic_cancer_primary_site',
      display_name: 'Primary Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'primary cancer site').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 2).first_or_create

    #End metastatic cancer primary site

    #Begin Laterality
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site_laterality',
      display_name: 'Laterality',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'laterality').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 3).first_or_create

    #End Laterality

    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => metastatic_cancer_group, :display_order => 4).first_or_create

    #End recurrent

    #End metastatic

    #Begin IDH1 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh1_status',
      display_name: 'IDH1 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh1').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create

    #End IDH1 status

    #Begin IDH2 status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_idh2_status',
      display_name: 'IDH2 Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'idh2').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End IDH2 status

    #Begin 1p status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_1p_status',
      display_name: '1P Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '1P').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End 1p status

    #Begin 19q status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_19q_status',
      display_name: '19q Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '19Q').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End 19q status

    #Begin 10q/PTEN status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_10q_PTEN_status',
      display_name: '10q/PTEN Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: '10q/PTEN').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End 10q/PTEN status

    #Begin MGMT promoter methylation status Status status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_mgmt_status',
      display_name: 'MGMT promoter methylation status Status',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'MGMT').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End MGMT promoter methylation status Status

    #Begin ki67
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_ki67',
      display_name: 'ki67',
      abstractor_object_type: number_object_type,
      preferred_name: 'ki67').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End ki67

    #Begin p53
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_p53',
      display_name: 'p53',
      abstractor_object_type: number_object_type,
      preferred_name: 'p53').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
    #End p53

    #outside surgical pathology report abstractions setup end

    #molecular genetics report abstractions setup begin
    abstractor_namespace_molecular_pathology = Abstractor::AbstractorNamespace.where(name: 'Molecular Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note ON note_stable_identifier.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4019097",
     where_clause: "note.note_title = 'Interpretation'").first_or_create

     abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
       predicate: 'has_mgmt_status',
       display_name: 'MGMT promoter methylation status Status',
       abstractor_object_type: radio_button_list_object_type,
       preferred_name: 'MGMT').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_molecular_pathology.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_spacy').first_or_create
  end
end