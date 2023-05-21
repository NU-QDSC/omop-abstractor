require 'rails_helper'
RSpec.feature 'Listing and searching abstractor object values.  User should be able to list and search for abstractor object values', type: :system do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.encounter_note
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.radiation_therapy_prescription
    OmopAbstractor::SpecSetup.pathology_case
    OmopAbstractor::SpecSetup.imaging_exam
  end

  scenario 'Viewing and searching a list of abstractor object values', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Anatomical location').first

    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end
    abstractor_object_values = abstractor_abstraction_schema.abstractor_object_values.order(:value).limit(10)
    abstractor_object_values.each do |abstractor_object_value|
      expect(all("#abstractor_abstractor_object_value_#{abstractor_object_value.id}")[0].find('.abstractor_object_value_value')).to have_content(abstractor_object_value.value)
      expect(all("#abstractor_abstractor_object_value_#{abstractor_object_value.id}")[0].find('.abstractor_object_value_vocabulary_code')).to have_content(abstractor_object_value.vocabulary_code)
    end
    fill_in 'Search', with: 'abdomen'
    click_button('Search')
    match_abstractor_object_value_row('abdomen, nos', 'C76.2', 0)
    match_abstractor_object_value_row('connective, subcutaneous and other soft tissues of abdomen', 'C49.4', 1)
    match_abstractor_object_value_row('peripheral nerves and autonomic nervous system of abdomen', 'C47.4', 2)
  end

  scenario 'Deleting an abstractor object value', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Anatomical location').first

    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end
    abstractor_object_values = abstractor_abstraction_schema.abstractor_object_values.order(:value).limit(10)
    abstractor_object_values.each do |abstractor_object_value|
      expect(all("#abstractor_abstractor_object_value_#{abstractor_object_value.id}")[0].find('.abstractor_object_value_value')).to have_content(abstractor_object_value.value)
      expect(all("#abstractor_abstractor_object_value_#{abstractor_object_value.id}")[0].find('.abstractor_object_value_vocabulary_code')).to have_content(abstractor_object_value.vocabulary_code)
    end
    fill_in 'Search', with: 'abdomen'
    click_button('Search')
    match_abstractor_object_value_row('abdomen, nos', 'C76.2', 0)
    match_abstractor_object_value_row('connective, subcutaneous and other soft tissues of abdomen', 'C49.4', 1)
    match_abstractor_object_value_row('peripheral nerves and autonomic nervous system of abdomen', 'C47.4', 2)

    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(value: 'abdomen, nos').first
    within("#abstractor_abstractor_object_value_#{abstractor_object_value.id}") do
      accept_confirm do
        click_link('Delete')
      end
    end
    fill_in 'Search', with: 'abdomen'
    click_button('Search')
    match_abstractor_object_value_row('connective, subcutaneous and other soft tissues of abdomen', 'C49.4', 0)
    match_abstractor_object_value_row('peripheral nerves and autonomic nervous system of abdomen', 'C47.4', 1)
  end
end