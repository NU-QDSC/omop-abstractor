require 'rails_helper'
RSpec.feature 'Adding an abstractor object value.  User should be able to add an abstractor object value', type: :system do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.encounter_note
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.radiation_therapy_prescription
    OmopAbstractor::SpecSetup.pathology_case
    OmopAbstractor::SpecSetup.surgery
    OmopAbstractor::SpecSetup.imaging_exam
  end

  scenario 'Adding an abstractor object value', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Anatomical location').first

    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end
    click_link('New')
    fill_in 'Value', with: 'moomin'
    fill_in 'Vocabulary Code', with: 'moomin code'
    fill_in 'Comments', with: 'moomin comments'
    scroll_to_bottom_of_the_page

    all('.abstractor_object_value_variants_list .value input')[0].set('moomin variant')
    all('.abstractor_object_value_variants_list .case_sensitive')[0].check('Case Sensitive?', allow_label_click: true)

    click_link('Add Variant Value')
    sleep(1)
    all('.abstractor_object_value_variants_list .value input')[1].set('moomin variant 2')
    all('.abstractor_object_value_variants_list .case_sensitive')[1].uncheck('Case Sensitive?', allow_label_click: true)


    click_button('Save')
    fill_in 'Search', with: 'moomin'
    click_button('Search')
    match_abstractor_object_value_row('moomin', 'moomin code', 0)
    abstractor_object_value = abstractor_abstraction_schema.abstractor_object_values.where(value: 'moomin').first
    within("#abstractor_abstractor_object_value_#{abstractor_object_value.id}") do
      click_link('Edit')
    end

    expect(page.has_field?('Value', with: 'moomin', disabled: false)).to be_truthy
    expect(page.has_field?('Vocabulary Code', with: 'moomin code', disabled: false)).to be_truthy
    expect(page.has_field?('Comments', with: 'moomin comments', disabled: false)).to be_truthy

    within(".abstractor_object_value_case_sensitive") do
      expect(page.has_checked_field?('Case Sensitive?', disabled: false, visible: false)).to be_falsy
    end

    match_abstractor_object_value_variant_row('moomin variant', true, false, 0)
    match_abstractor_object_value_variant_row('moomin variant 2', false, false, 1)
  end

  scenario 'Adding an abstractor object value with validation', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Anatomical location').first
    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end
    click_link('New')
    click_link('Add Variant Value')
    click_button('Save')
    expect(page).to have_css(".abstractor_object_value_value .invalid")
    expect(all(".abstractor_object_value_value .error")[0]).to have_content("can't be blank")

    expect(page).to have_css(".abstractor_object_value_vocabulary_code .invalid")
    expect(all(".abstractor_object_value_vocabulary_code .error")[0]).to have_content("can't be blank")
    expect(all('.abstractor-object-value-variant .value')[0]).to have_css('input.invalid')
  end
end