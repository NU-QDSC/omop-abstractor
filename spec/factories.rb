FactoryGirl.define do
  factory :relationship do
    relationship_id           nil
    relationship_name         nil
    is_hierarchical           nil
    defines_ancestry          nil
    reverse_relationship_id   nil
    relationship_concept_id   nil
  end

  factory :concept do
    concept_id          nil
    concept_name        nil
    domain_id           nil
    vocabulary_id       nil
    concept_class_id    nil
    standard_concept    nil
    concept_code        nil
    valid_start_date    Date.parse('1970-01-01')
    valid_end_date      Date.parse('2099-12-31')
    invalid_reason      nil
  end

  factory :pii_name do
    sequence(:first_name) do |n|
      "Bob #{n}"
    end
    sequence(:middle_name) do |n|
      "Jay #{n}"
    end
    sequence(:last_name) do |n|
      "Jones #{n}"
    end
    suffix          nil
    prefix          nil
  end

  factory :undefined_concept_class, class: ConceptClass do
    concept_class_id            'Undefined'
    concept_class_name          'Undefined'
    concept_class_concept_id    0
  end

  factory :undefined_concept, class: Concept do
    concept_id                  44819044
    concept_name                'Undefined'
    domain_id                   Concept::DOMAIN_ID_METADATA
    vocabulary_id               Concept::VOCABULARY_ID_CONCEPT_CLASS
    concept_class_id            Concept::CONCEPT_CLASS_UNDEFINED
    standard_concept            nil
    concept_code                'OMOP generated'
    valid_start_date            Date.parse('1970-01-01')
    valid_end_date              Date.parse('2099-12-31')
    invalid_reason              nil
  end

  factory :no_matching_concept, class: Concept do
    concept_id                  0
    concept_name                'No matching concept'
    domain_id                   Concept::DOMAIN_ID_METADATA
    vocabulary_id               Concept::VOCABULARY_ID_NONE
    concept_class_id            Concept::CONCEPT_CLASS_UNDEFINED
    standard_concept            nil
    concept_code                'No matching concept'
    valid_start_date            Date.parse('1970-01-01')
    valid_end_date              Date.parse('2099-12-31')
    invalid_reason              nil
  end

  factory :person do
    sequence(:person_id)
    gender_concept_id                       0
    year_of_birth                           1971
    month_of_birth                          12
    day_of_birth                            10
    birth_datetime                          Date.parse('1971-12-10')
    race_concept_id                         0
    ethnicity_concept_id                    0
    location_id                             nil
    provider_id                             nil
    care_site_id                            nil
    person_source_value                     nil
    gender_source_value                     nil
    gender_source_concept_id                0
    race_source_value                       nil
    race_source_concept_id                  0
    ethnicity_source_value                  nil
    ethnicity_source_concept_id             0
  end

  factory :note do
    sequence(:note_id)
    person_id                 nil
    note_date                 Date.parse('2019-01-01')
    note_datetime             Date.parse('2019-01-01')
    note_type_concept_id      0
    note_class_concept_id     0
    note_title                ''
    note_text                 ''
    encoding_concept_id       0
    language_concept_id       0
    provider_id               nil
    visit_occurrence_id       nil
    visit_detail_id           nil
    note_source_value         nil
  end

  factory :note_stable_identifier do
    note_id                     nil
    stable_identifier_path      ''
    stable_identifier_value     ''
  end

  factory :procedure_occurrence do
    sequence(:procedure_occurrence_id)
    person_id                    nil
    procedure_concept_id         0
    procedure_date               Date.parse('2019-01-01')
    procedure_datetime           Date.parse('2019-01-01')
    procedure_type_concept_id    0
    modifier_concept_id          0
    quantity                     nil
    provider_id                  nil
    visit_occurrence_id          nil
    visit_detail_id              nil
    procedure_source_value       nil
    procedure_source_concept_id  0
    modifier_source_value        nil
  end

  factory :fact_relationship do
    domain_concept_id_1         nil
    fact_id_1                   nil
    domain_concept_id_2         nil
    fact_id_2                   nil
    relationship_concept_id     nil
  end

  factory :user do
  end

  factory :abstractor_subject, :class => Abstractor::AbstractorSubject do
  end

  factory :abstractor_abstraction_schema, class: Abstractor::AbstractorAbstractionSchema do
  end

  factory :abstractor_abstraction_schema_predicate_variant, class: Abstractor::AbstractorAbstractionSchemaPredicateVariant do
  end

  factory :abstractor_abstraction_source, class: Abstractor::AbstractorAbstractionSource do
  end

  factory :abstractor_object_value, class: Abstractor::AbstractorObjectValue do
    value '1'
    vocabulary_code '1'
    vocabulary '1'
    vocabulary_version '1'
  end

  factory :abstractor_object_value_variant, class: Abstractor::AbstractorObjectValueVariant do
  end

  factory :abstractor_abstraction, class: Abstractor::AbstractorAbstraction do
  end

  factory :abstractor_suggestion, class: Abstractor::AbstractorSuggestion do
  end

  factory :abstractor_suggestion_source, class: Abstractor::AbstractorSuggestionSource do
  end

  factory :abstractor_subject_group, :class => Abstractor::AbstractorSubjectGroup do
    cardinality nil
  end

  factory :abstractor_rule, :class => Abstractor::AbstractorRule do
  end

  factory :abstractor_section, :class => Abstractor::AbstractorSection do
  end

  factory :abstractor_section_name_variant, :class => Abstractor::AbstractorSectionNameVariant do
  end

  factory :abstractor_abstraction_source_section, :class => Abstractor::AbstractorAbstractionSourceSection do
  end
end