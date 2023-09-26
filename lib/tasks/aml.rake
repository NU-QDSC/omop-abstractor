# ohdsi nlp proposal
  # data
  # bundle exec rake setup:truncate_stable_identifiers
  # bundle exec rake omop:truncate_omop_clinical_data_tables
  # bundle exec rake setup:aml_data
  # bundle exec rake setup:aml_test_data

  #schemas
  # bundle exec rake abstractor:setup:system
  # bundle exec rake setup:compare_icdo3
  # bundle exec rake setup:truncate_schemas
  # bundle exec rake aml:schemas

  #abstraction will
  # bundle exec rake suggestor:do_multiple_aml
  # bundle exec rake ohdsi_nlp_proposal:create_ohdsi_nlp_proposal_pathology_cases_datamart
namespace :aml do
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

    abstractor_namespace_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Diagnostic Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id IN(4213297, 4192879, 4094377)",
    where_clause: "note.note_title in('Bone Marrow Final Diagnosis', 'Conversion Final Diagnosis', 'Final Diagnosis', 'Final Diagnosis Rendered', 'Final Pathologic Diagnosis', 'Interpretation')").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    histologies = Icdo3Histology.by_primary_aml
    histologies.each do |histology|
      name = histology.icdo3_name.downcase
      if histology.icdo3_code != histology.icdo3_name
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name} (#{histology.icdo3_code})".downcase, vocabulary_code: histology.icdo3_code, vocabulary: 'ICD-O-3.2', vocabulary_version: 'ICD-O-3.2').first_or_create
      else
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(:value => "#{name}", vocabulary_code: "#{name}".downcase).first_or_create
      end

      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
      # puts "hello 1 #{name} goodbye"
      Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => name).first_or_create

      normalized_values = OmopAbstractor::Setup.normalize(name.downcase)
      normalized_values.uniq!
      normalized_values.each do |normalized_value|
        if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value.downcase) && !OmopAbstractor::Setup.object_value_variant_exists?(histology.icdo3_code, normalized_value.downcase)
          # puts "hello 2 #{normalized_value} goodbye"
          Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
        end
      end

      histology_synonyms = Icdo3Histology.by_icdo3_code_with_synonyms(histology.icdo3_code)
      histology_synonyms.each do |histology_synonym|
        normalized_values = OmopAbstractor::Setup.normalize(histology_synonym.icdo3_synonym_description.downcase)
        normalized_values.uniq!
        normalized_values.each do |normalized_value|
          if !OmopAbstractor::Setup.object_value_exists?(abstractor_abstraction_schema, normalized_value.downcase) && !OmopAbstractor::Setup.object_value_variant_exists?(histology.icdo3_code, normalized_value.downcase)
            # puts "hello 3 #{normalized_value} goodbye"
            Abstractor::AbstractorObjectValueVariant.where(:abstractor_object_value => abstractor_object_value, :value => normalized_value.downcase).first_or_create
          end
        end
      end
    end

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: false).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

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
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value_recurrent, value: 'persistent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will', section_required: false).first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 4).first_or_create
    #End recurrent
    #End primary cancer

    abstractor_namespace_outside_surgical_pathology = Abstractor::AbstractorNamespace.where(name: 'Outside Diagnostic Pathology', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN fact_relationship ON fact_relationship.domain_concept_id_1 = 5085 AND fact_relationship.fact_id_1 = note.note_id AND fact_relationship.relationship_concept_id = 44818790
     JOIN procedure_occurrence ON fact_relationship.domain_concept_id_2 = 10 AND fact_relationship.fact_id_2 = procedure_occurrence.procedure_occurrence_id AND procedure_occurrence.procedure_concept_id = 4244107",
    where_clause: "note.note_title IN('Final Diagnosis', 'Final Diagnosis Rendered', 'Interpretation')").first_or_create

    #Begin primary cancer
    primary_cancer_group = Abstractor::AbstractorSubjectGroup.where(name: 'Primary Cancer', enable_workflow_status: false).first_or_create
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: true).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 1).first_or_create

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
    #Begin recurrent
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_recurrence_status',
      display_name: 'Recurrent',
      abstractor_object_type: radio_button_list_object_type,
      preferred_name: 'recurrent').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_outside_surgical_pathology.id, anchor: false, default_abstractor_object_value_id: abstractor_object_value_initial.id).first_or_create
    abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_will').first_or_create
    Abstractor::AbstractorSubjectGroupMember.where(:abstractor_subject => abstractor_subject, :abstractor_subject_group => primary_cancer_group, :display_order => 5).first_or_create

    #End recurrent
  end

  # bundle exec rake ohdsi_nlp_proposal:load_clinical_data
  desc "Load clinical data"
  task(load_clinical_data: :environment) do |t, args|
    location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
    gender_concept_id = Concept.genders.first.concept_id
    race_concept_id = Concept.races.first.concept_id
    ethnicity_concept_id =   Concept.ethnicities.first.concept_id

    file = "lib/setup/data/ohdsi_nlp_proposal/condition_occurrences.csv"
    file_clean = "lib/setup/data/ohdsi_nlp_proposal/condition_occurrences clean.csv"
    open(file_clean, 'w') { |f|
      File.open(file, 'r:bom|utf-8').each_line { |line|
        line.encode!('UTF-8', invalid: :replace, undef: :replace)
        f.puts line
      }
    }

    ConditionOccurrence.where('condition_type_concept_id != 32858').delete_all
    condition_occurrences_from_file = CSV.new(File.open(file_clean), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")
    condition_occurrence_id = ConditionOccurrence.maximum(:condition_occurrence_id)
    if condition_occurrence_id.blank?
      condition_occurrence_id = 0
    end
    condition_occurrence_id+=1
    condition_occurrences_from_file.each do |condition_occurrence_from_file|
      condition_occurrence_from_file = condition_occurrence_from_file.to_hash
      puts condition_occurrence_from_file['source_system_name']
      puts condition_occurrence_from_file['west_mrn']
      puts condition_occurrence_from_file['event_type']
      puts condition_occurrence_from_file['diagnosis_code_set']
      puts condition_occurrence_from_file['diagnosis_code']
      puts condition_occurrence_from_file['start_date_key']
      puts condition_occurrence_from_file['end_date_key']
      west_mrn = condition_occurrence_from_file['west_mrn']

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
      case condition_occurrence_from_file['diagnosis_code_set']
      when 'ICD-9-CM'
        vocabulary_id = 'ICD9CM'
      when 'ICD-10-CM'
        vocabulary_id = 'ICD10CM'
      end
      case condition_occurrence_from_file['event_type']
      when 'Billing Diagnosis'
        condition_typ_concept_id = 32821
      when 'Encounter Diagnosis'
        condition_typ_concept_id = 32827
      when 'Hospital Admission'
        condition_typ_concept_id = 32819
      when 'Problem List'
        condition_typ_concept_id = 32840
      end
      concept = Concept.where(vocabulary_id: vocabulary_id, concept_code: condition_occurrence_from_file['diagnosis_code'], domain_id: 'Condition').first
      concept_relationship = ConceptRelationship.where(concept_id_1: concept.concept_id, relationship_id: 'Maps to').first
      if concept_relationship
        concept_id = concept_relationship.concept_id_2
        condition_occurrence = ConditionOccurrence.new
        condition_occurrence.condition_occurrence_id = condition_occurrence_id
        condition_occurrence.person_id = person.person_id
        condition_occurrence.condition_concept_id = concept_id
        condition_occurrence.condition_start_date = Date.parse(condition_occurrence_from_file['start_date_key'])
        if condition_occurrence_from_file['end_date_key']
          condition_occurrence.condition_end_date = Date.parse(condition_occurrence_from_file['end_date_key'])
        end
        condition_occurrence.condition_type_concept_id = condition_typ_concept_id
        condition_occurrence.save!
        condition_occurrence_id+=1
      end
    end
  end

  #bundle exec rake aml:create_aml_pathology_cases_datamart
  desc "Create AML Pathology Cases Datamart"
  task(create_aml_pathology_cases_datamart: :environment) do |t, args|
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE aml_pathology_cases CASCADE;')
    sql_file = "#{Rails.root}/lib/tasks/aml_pathology_cases.sql"
    sql = File.read(sql_file)
    ActiveRecord::Base.connection.execute(sql)
  end

  #bundle exec rake ohdsi_nlp_proposal:load_nlp_derived_clinical
  desc 'Load NLP-derived clinical data'
  task(load_nlp_derived_clinical: :environment) do |t, args|
    ConditionOccurrence.where('condition_type_concept_id = 32858').delete_all
    Measurement.where('measurement_type_concept_id = 32858').delete_all
    NoteNlp.delete_all
    condition_occurrence_id = ConditionOccurrence.maximum(:condition_occurrence_id)
    if condition_occurrence_id.blank?
      condition_occurrence_id = 0
    end
    condition_occurrence_id+=1

    measurement_id = Measurement.maximum(:measurement_id)
    if measurement_id.blank?
      measurement_id = 0
    end
    measurement_id+=1

    note_nlp_id = NoteNlp.maximum(:note_nlp_id)
    if note_nlp_id.blank?
      note_nlp_id = 0
    end
    note_nlp_id+=1

    OhdsiNlpProposalPathologyCase.where("diagnosis_type = 'Primary Cancer' AND has_cancer_histology IS NOT NULL AND has_cancer_histology!= 'not applicable' AND has_cancer_site IS NOT NULL AND has_cancer_site != 'not applicable'").each do |pathology_case|
      person =  Person.where(person_source_value: pathology_case.west_mrn).first
      icdo3_histology = Abstractor::AbstractorObjectValue.where(value: pathology_case.has_cancer_histology).first
      icdo3_histology_code = icdo3_histology.vocabulary_code
      icdo3_site = Abstractor::AbstractorObjectValue.where(value: pathology_case.has_cancer_site).first
      icdo3_site_code = icdo3_site.vocabulary_code
      concept_code = "#{icdo3_histology_code}-#{icdo3_site_code}"

      puts 'here is the icdo3_histology_code/icdo3_site_code combination'
      puts concept_code
      concept = Concept.where(vocabulary_id: 'ICDO3', concept_code: concept_code, domain_id: 'Condition').first
      concept_relationship = nil
      if concept
        puts 'Found it!'
        concept_relationship = ConceptRelationship.where(concept_id_1: concept.concept_id, relationship_id: 'Maps to').first
      else
        puts 'Did not find it!'
        puts concept_code
      end

      if concept_relationship
        condition_concept_id = concept_relationship.concept_id_2
        condition_occurrence = ConditionOccurrence.new
        condition_occurrence.condition_occurrence_id = condition_occurrence_id
        condition_occurrence.person_id = person.person_id
        condition_occurrence.condition_concept_id = condition_concept_id
        case pathology_case.abstractor_namespace_name
        when 'Surgical Pathology'
          condition_start_date = pathology_case.pathology_procedure_date
        when 'Outside Surgical Pathology'
          if pathology_case.has_surgery_date.present? && pathology_case.has_surgery_date != 'not applicable'
            condition_start_date = Date.parse(pathology_case.has_surgery_date)
          else
            condition_start_date = pathology_case.pathology_procedure_date
          end
        end
        condition_occurrence.condition_start_date = condition_start_date
        condition_occurrence.condition_type_concept_id = 32858 #NLP
        condition_occurrence.save!
        condition_occurrence_id+=1

        note_nlp_condition_occurrence = NoteNlp.new
        note_nlp_condition_occurrence.note_nlp_id = note_nlp_id
        note_nlp_condition_occurrence.note_id = pathology_case.note_id
        note_nlp_condition_occurrence.note_nlp_concept_id = condition_concept_id
  			note_nlp_condition_occurrence.nlp_event_id = condition_occurrence.condition_occurrence_id
  			note_nlp_condition_occurrence.nlp_event_field_concept_id = 1147127 #condition_occurrence.condition_occurrence_id
        note_nlp_condition_occurrence.lexical_variant = ''
        note_nlp_condition_occurrence.nlp_date = Date.today
        note_nlp_condition_occurrence.save!
        note_nlp_id+=1

        puts 'has_cancer_who_grade'
        puts pathology_case.has_cancer_who_grade
        if pathology_case.has_cancer_who_grade.present? && pathology_case.has_cancer_who_grade != 'not applicable'
          measurement = Measurement.new
          measurement.measurement_id = measurement_id
          measurement.person_id = person.person_id

          case pathology_case.has_cancer_who_grade
          when 'Grade 1'
            measurement_concept_id = 1634371 #WHO Grade I
          when 'Grade 2'
            measurement_concept_id = 1634752 #WHO Grade II
          when 'Grade 3'
            measurement_concept_id = 1633749 #WHO Grade III
          when 'Grade 4'
            measurement_concept_id = 1635792 #WHO Grade IV
          end
          puts 'here we are'
          puts measurement_concept_id
          measurement.measurement_concept_id = measurement_concept_id
          case pathology_case.abstractor_namespace_name
          when 'Surgical Pathology'
            measurement_date = pathology_case.pathology_procedure_date
          when 'Outside Surgical Pathology'
            if pathology_case.has_surgery_date.present? && pathology_case.has_surgery_date != 'not applicable'
              measurement_date = Date.parse(pathology_case.has_surgery_date)
            else
              measurement_date = pathology_case.pathology_procedure_date
            end
          end

          measurement.measurement_date = measurement_date
          measurement.measurement_type_concept_id = 32858 #NLP
          measurement.measurement_event_id = condition_occurrence.condition_occurrence_id
          measurement.meas_event_field_concept_id = 1147127 #condition_occurrence.condition_occurrence_id
          measurement.value_as_concept_id = 0
          measurement.unit_concept_id = 0
          measurement.save!
          measurement_id+=1

          note_nlp_measurement = NoteNlp.new
          note_nlp_measurement.note_nlp_id = note_nlp_id
          note_nlp_measurement.note_id = pathology_case.note_id
          note_nlp_measurement.note_nlp_concept_id = measurement_concept_id
    			note_nlp_measurement.nlp_event_id = measurement.measurement_id
    			note_nlp_measurement.nlp_event_field_concept_id = 1147138 #measurement.measurement_id
          note_nlp_measurement.lexical_variant = ''
          note_nlp_measurement.nlp_date = Date.today
          note_nlp_measurement.save!
          note_nlp_id+=1
        end

        puts 'has_cancer_recurrence_status'
        puts pathology_case.has_cancer_recurrence_status
        if pathology_case.has_cancer_recurrence_status == 'initial'
          measurement = Measurement.new
          measurement.measurement_id = measurement_id
          measurement.person_id = person.person_id
          measurement_concept_id = 734306 #Initial Diagnosis

          puts 'here we are'
          puts measurement_concept_id
          measurement.measurement_concept_id = measurement_concept_id
          case pathology_case.abstractor_namespace_name
          when 'Surgical Pathology'
            measurement_date = pathology_case.pathology_procedure_date
          when 'Outside Surgical Pathology'
            if pathology_case.has_surgery_date.present? && pathology_case.has_surgery_date != 'not applicable'
              measurement_date = Date.parse(pathology_case.has_surgery_date)
            else
              measurement_date = pathology_case.pathology_procedure_date
            end
          end

          measurement.measurement_date = measurement_date
          measurement.measurement_type_concept_id = 32858 #NLP
          measurement.measurement_event_id = condition_occurrence.condition_occurrence_id
          measurement.meas_event_field_concept_id = 1147127 #condition_occurrence.condition_occurrence_id
          measurement.value_as_concept_id = 0
          measurement.unit_concept_id = 0
          measurement.save!
          measurement_id+=1

          note_nlp_measurement = NoteNlp.new
          note_nlp_measurement.note_nlp_id = note_nlp_id
          note_nlp_measurement.note_id = pathology_case.note_id
          note_nlp_measurement.note_nlp_concept_id = measurement_concept_id
    			note_nlp_measurement.nlp_event_id = measurement.measurement_id
    			note_nlp_measurement.nlp_event_field_concept_id = 1147138 #measurement.measurement_id
          note_nlp_measurement.lexical_variant = ''
          note_nlp_measurement.nlp_date = Date.today
          note_nlp_measurement.save!
          note_nlp_id+=1
        end
      end
    end
  end
end