require 'rails_helper'
RSpec.feature 'Editing pathology case: User should be able to edit pathology case information', type: :system do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.pathology_case
    OmopAbstractor::SpecSetup.surgery
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @pii_name = FactoryGirl.create(:pii_name, person_id: @person.person_id)
    FactoryGirl.create(:concept, concept_id: 10, concept_name: 'Procedure', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:concept, concept_id: 5085, concept_name: 'Note', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:concept, concept_id: 44818790, concept_name: 'Has procedure context (SNOMED)', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_RELATIONSHIP, concept_class_id: Concept::CONCEPT_CLASS_RELATIONSHIP, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:relationship, relationship_id: 'Has proc context', relationship_name: 'Has procedure context (SNOMED)', is_hierarchical: 0, defines_ancestry: 0, reverse_relationship_id: 'Proc context of', relationship_concept_id: 44818790)
  end

  scenario 'User editing an abstraction with a dynamic list', js: true, focus: false do
    pending "Expected to fail: Need to figure out if supporting dynamic lists still makes sense."
    @abstractor_namespace_pathology_case = Abstractor::AbstractorNamespace.where(name: 'Pathology Case', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create
    note_text = "Hello, you look good to me."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_pathology_case.id)

    create_surgeries([ { 'Surgery Case ID' => 100, 'Surgery Case Number' => 'OR-123',  'Patient ID' => 1 }, { 'Surgery Case ID' => 101, 'Surgery Case Number' => 'OR-124',  'Patient ID' => 1 }, { 'Surgery Case ID' => 101, 'Surgery Case Number' => 'OR-125',  'Patient ID' => 2 }])

    @abstractable = PathologyCase.last
    visit(edit_pathology_case_path(@abstractable))
    within('.has_surgery') do
      click_link('Edit')
    end

    surgery_case_number = 'OR-124'
    find('.custom-combobox-input').send_keys(surgery_case_number)
    find("ul.ui-autocomplete li.ui-menu-item", text: surgery_case_number).click()
    click_button('Save')
    sleep(1)
    within(".has_surgery") do
      expect(find_field('101')['checked']).to be_truthy
    end
  end
end

def create_pathology_cases(pathology_cases)
  pathology_cases.each_with_index do |pathology_case_hash, i|
    pathology_case = FactoryGirl.create(:pathology_case, note_text: pathology_case_hash['Note Text'], patient_id: pathology_case_hash['Patient ID'])
    pathology_case.abstract
    if pathology_case_hash['Status'] && pathology_case_hash['Status'] == 'Reviewed'
      abstractor_suggestion_status_accepted= AbstractorSuggestionStatus.where(:name => 'Accepted').first
      pathology_case.reload.abstractor_abstractions(true).each do |abstractor_abstraction|
        abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
          abstractor_suggestion.abstractor_suggestion_status = abstractor_suggestion_status_accepted
          abstractor_suggestion.save!
        end
      end
    end
  end
end

def create_surgeries(surgeries)
  surgeries.each_with_index do |surgery_hash, i|
    surgery = FactoryGirl.create(:surgery, surg_case_id: surgery_hash['Surgery Case ID'], surg_case_nbr: surgery_hash['Surgery Case Number'], patient_id: surgery_hash['Patient ID'])
    surgery.abstract
  end
end