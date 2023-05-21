require './lib/omop_abstractor/setup/setup'
require './lib/tasks/omop_abstractor_clamp_dictionary_exporter'
namespace :nmccor do
  desc 'Load schemas CLAMP NMCCOR'
  task(schemas_clamp_nmccor: :environment) do |t, args|
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

    abstractor_namespace_clinic_visit = Abstractor::AbstractorNamespace.where(name: 'Clinic Visits', subject_type: NoteStableIdentifier.to_s, joins_clause:
    "JOIN note_stable_identifier_full ON note_stable_identifier.stable_identifier_path = note_stable_identifier_full.stable_identifier_path AND note_stable_identifier.stable_identifier_value = note_stable_identifier_full.stable_identifier_value
     JOIN note ON note_stable_identifier_full.note_id = note.note_id
     JOIN visit_occurrence ON note.visit_occurrence_id = visit_occurrence.visit_occurrence_id",
    where_clause: '').first_or_create
    abstractor_namespace_clinic_visit.save!


    #Begin ECOG Performance Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_ecog_performance_status',
      display_name: 'ECOG Performance Status',
      abstractor_object_type: list_object_type,
      preferred_name: 'ecog').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'ps:').first_or_create
    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'performance status').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '0', vocabulary_code: '0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '00').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'zero').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '1', vocabulary_code: '1').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '01').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '2', vocabulary_code: '2').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '02').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '3', vocabulary_code: '3').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '03').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '4', vocabulary_code: '4').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '04').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '5', vocabulary_code: '5').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '05').first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_clinic_visit.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_clamp').first_or_create
    #End ECOG Performance Status

    #Begin Karnofsky Performance Status
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_karnofsky_performance_status',
      display_name: 'Karnofsky Performance Status',
      abstractor_object_type: list_object_type,
      preferred_name: 'karnofsky').first_or_create

    Abstractor::AbstractorAbstractionSchemaPredicateVariant.where(abstractor_abstraction_schema: abstractor_abstraction_schema, value: 'kps').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '0', vocabulary_code: '0').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '00').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '000').first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: 'zero').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '10', vocabulary_code: '10').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '010').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '20', vocabulary_code: '20').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '020').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '30', vocabulary_code: '30').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '030').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '40', vocabulary_code: '40').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '040').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '50', vocabulary_code: '50').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '050').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '60', vocabulary_code: '60').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '060').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '70', vocabulary_code: '70').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '070').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '80', vocabulary_code: '80').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '080').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '90', vocabulary_code: '90').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create
    Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: '090').first_or_create

    abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: '100', vocabulary_code: '100').first_or_create
    Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

    abstractor_subject = Abstractor::AbstractorSubject.where(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: abstractor_namespace_clinic_visit.id).first_or_create
    Abstractor::AbstractorAbstractionSource.where(abstractor_subject: abstractor_subject, from_method: 'note_text', :abstractor_rule_type => name_value_rule, abstractor_abstraction_source_type: source_type_custom_nlp_suggestion, custom_nlp_provider: 'custom_nlp_provider_clamp').first_or_create
    #End Karnofsky Performance Status
  end

  desc "Clamp Dictionary NMCCOR"
  task(clamp_dictionary_nmccor: :environment) do  |t, args|
    dictionary_items = []

    predicates = []
    predicates << 'has_ecog_performance_status'
    predicates << 'has_karnofsky_performance_status'

    Abstractor::AbstractorAbstractionSchema.where(predicate: predicates).all.each do |abstractor_abstraction_schema|
      rule_type = abstractor_abstraction_schema.abstractor_subjects.first.abstractor_abstraction_sources.first.abstractor_rule_type.name
      puts 'hello'
      puts abstractor_abstraction_schema.predicate
      puts rule_type
      case rule_type
      when Abstractor::Enum::ABSTRACTOR_RULE_TYPE_VALUE
        dictionary_items.concat(OmopAbstractorClampDictionaryExporter::create_value_dictionary_items(abstractor_abstraction_schema))
      when Abstractor::Enum::ABSTRACTOR_RULE_TYPE_NAME_VALUE
        puts 'this is the one'
        dictionary_items.concat(OmopAbstractorClampDictionaryExporter::create_name_dictionary_items(abstractor_abstraction_schema))
        if !abstractor_abstraction_schema.positive_negative_object_type_list? && !abstractor_abstraction_schema.deleted_non_deleted_object_type_list? && abstractor_abstraction_schema.predicate != 'has_metastatic_cancer_primary_site'
          dictionary_items.concat(OmopAbstractorClampDictionaryExporter::create_value_dictionary_items(abstractor_abstraction_schema))
        end
      end
    end
    puts 'how much?'
    puts dictionary_items.length

    File.open 'lib/setup/data_out/abstractor_clamp_nmccor_data_dictionary.txt', 'w' do |f|
      dictionary_items.each do |di|
        f.puts di
      end
    end
  end

  desc "Load NMCCOR data"
  task(nmccor_data: :environment) do |t, args|
    nmccor_clinic_visits = CSV.new(File.open('lib/setup/data/nmccor_clinic_visits.csv'), headers: true, col_sep: ",", return_headers: false,  quote_char: "\"")

    nmccor_clinic_visits.each_with_index do |nmccor_clinic_visit, i|
      location = Location.where(location_id: 1, address_1: '123 Main Street', address_2: 'Apt, 3F', city: 'New York', state: 'NY' , zip: '10001', county: 'Manhattan').first_or_create
      person = Person.where(person_source_value: nmccor_clinic_visit['west_mrn']).first
      puts i
      puts 'hello'
      puts nmccor_clinic_visit['west_mrn']
      if person.blank?
        person = Person.where(person_id: i+1, gender_concept_id: Concept.genders.first, year_of_birth: 1971, month_of_birth: 12, day_of_birth: 10, birth_datetime: DateTime.parse('12/10/1971'), race_concept_id: Concept.races.first, ethnicity_concept_id: Concept.ethnicities.first, person_source_value: nmccor_clinic_visit['west_mrn'], location: location).first_or_create
        location = Location.where(location_id: 2, address_1: '123 Main St', address_2: '3F', city: 'Chicago', state: 'IL', zip: '60657', county: 'Cook', location_source_value: nil).first_or_create
        person.adresses.where(location: location).first_or_create
        person.emails.where(email: 'person1@ohdsi.org').first_or_create
        person.mrns.where(health_system: 'NMHC',  mrn: nmccor_clinic_visit['west_mrn']).first_or_create
        if person.name
          person.name.destroy!
        end
        person.build_name(first_name: 'Harold', middle_name: nil , last_name: 'Baines' , suffix: 'Mr' , prefix: nil)
        person.save!
        person.phone_numbers.where(phone_number: '8471111111').first_or_create
      end

      #progress report begin
      gender_concept = Concept.genders.where(concept_name: 'MALE').first
      provider = Provider.where(provider_id: 1, provider_name: 'Craig Horbinski', npi: '1730345026', dea: nil, specialty_concept_id: nil, care_site_id: nil, year_of_birth: Date.parse('1/1/1968').year, gender_concept_id: gender_concept.concept_id, provider_source_value: nil, specialty_source_value: nil, specialty_source_concept_id: nil, gender_source_value: nil, gender_source_concept_id: nil).first_or_create
      visit_concept = Concept.visit_concepts.where(concept_id: 581477).first        #Office Visit
      visit_type_concept = Concept.visit_types.where(concept_id: 44818518).first    #Visit derived from EHR record

      visit_source_value = "#{nmccor_clinic_visit['speciality']}:#{nmccor_clinic_visit['department_name']}".truncate(50)
      visit_occurrence = VisitOccurrence.where(visit_occurrence_id: i, person_id: person.person_id, visit_concept_id: visit_concept.concept_id, visit_start_date: Date.parse(nmccor_clinic_visit['contact_date']), visit_end_date: Date.parse(nmccor_clinic_visit['contact_date']), visit_type_concept_id: visit_type_concept.concept_id, visit_source_value: visit_source_value).first_or_create

      note_type_concept = Concept.note_types.where(concept_id: 44814640).first #Outpatient note
      note_class_concept = Concept.valid.where(concept_id: 36205960).first #Progress note | Outpatient

      note_text = nmccor_clinic_visit['note_text']
      note = Note.where(note_id: i, person_id: person.person_id, note_date: Date.parse(nmccor_clinic_visit['contact_date']), note_type_concept_id: note_type_concept.concept_id, note_class_concept_id: note_class_concept.concept_id, note_title: 'Progress Report', note_text: note_text, encoding_concept_id: 0, language_concept_id: 0, provider_id: provider.provider_id, visit_occurrence_id: visit_occurrence.visit_occurrence_id, note_source_value: nil).first_or_create
      if note.note_stable_identifier.blank?
        NoteStableIdentifierFull.where(note_id: note.note_id, stable_identifier_path: 'stable_identifier_path', stable_identifier_value: "#{note.note_id}").first_or_create
      end
      #progress report end
    end
  end
end