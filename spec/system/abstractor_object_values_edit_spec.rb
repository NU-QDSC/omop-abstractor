require 'rails_helper'
RSpec.feature 'Abstractor Object Values Edit', type: :system do
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
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  describe 'User should be able to edit an abstractor object value' do
    scenario 'Prevent editing an abstractor object value with suggestions', js: true, focus: false do
      [{ site: 'abdominal wall, nos' }].each_with_index do |radiation_therapy_prescription_hash, i|
        note = FactoryGirl.create(:note, person: @person, note_text: radiation_therapy_prescription_hash[:site])
        note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
        note_stable_identifier.abstract
      end

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
        click_link('Edit')
      end

      expect(page.has_field?('Value', with: 'abdomen, nos', disabled: true)).to be_truthy
      expect(page.has_field?('Vocabulary Code', with: 'C76.2', disabled: true)).to be_truthy
      expect(page.has_field?('Comments', with: '', disabled: false)).to be_truthy
      within(".abstractor_object_value_case_sensitive") do
        expect(page.has_unchecked_field?('Case Sensitive?', disabled: false, visible: false)).to be_falsy
      end
      scroll_to_bottom_of_the_page

      match_abstractor_object_value_variant_row('abdominal wall, nos', false, true, 0)
      match_abstractor_object_value_variant_row('intra-abdominal site, nos', false, false, 1)
    end
  end

  scenario 'Allowing edit of an abstractor object value without suggestions', js: true, focus: false do
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
      click_link('Edit')
    end

    expect(page.has_field?('Value', with: 'abdomen, nos', disabled: false)).to be_truthy
    expect(page.has_field?('Vocabulary Code', with: 'C76.2', disabled: false)).to be_truthy
    expect(page.has_field?('Comments', with: nil, disabled: false)).to be_truthy
    expect(page.has_unchecked_field?('Case Sensitive?', disabled: false, visible: false)).to be_truthy

    match_abstractor_object_value_variant_row('abdominal wall, nos', false, false, 0)
    match_abstractor_object_value_variant_row('intra-abdominal site, nos', false, false, 1)
  end

  scenario 'Searching a list of abstractor object values', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Anatomical location').first
    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end

    expect(all(".abstractor_abstractor_object_value")[0].find('.abstractor_object_value_value')).to have_content('abdomen, nos')
    expect(all(".abstractor_abstractor_object_value")[1].find('.abstractor_object_value_value')).to have_content('abdominal esophagus')
    expect(all(".abstractor_abstractor_object_value")[2].find('.abstractor_object_value_value')).to have_content('accessory sinus, nos')
    expect(all(".abstractor_abstractor_object_value")[3].find('.abstractor_object_value_value')).to have_content('accessory sinuses')
    expect(all(".abstractor_abstractor_object_value")[4].find('.abstractor_object_value_value')).to have_content('acoustic nerve')
    expect(all(".abstractor_abstractor_object_value")[5].find('.abstractor_object_value_value')).to have_content('adrenal gland')
    expect(all(".abstractor_abstractor_object_value")[6].find('.abstractor_object_value_value')).to have_content('adrenal gland, nos')
    expect(all(".abstractor_abstractor_object_value")[7].find('.abstractor_object_value_value')).to have_content('ampulla of vater')
    expect(all(".abstractor_abstractor_object_value")[8].find('.abstractor_object_value_value')).to have_content('anal canal')
    expect(all(".abstractor_abstractor_object_value")[9].find('.abstractor_object_value_value')).to have_content('anterior 2/3 of tongue, nos')
    fill_in 'Search', with: 'accessory'
    click_button('Search')
    sleep(1)

    expect(all(".abstractor_abstractor_object_value")[0].find('.abstractor_object_value_value')).to have_content('accessory sinus, nos')
    expect(all(".abstractor_abstractor_object_value")[1].find('.abstractor_object_value_value')).to have_content('accessory sinuses')
    expect(all(".abstractor_abstractor_object_value")[2].find('.abstractor_object_value_value')).to have_content('overlapping lesion of accessory sinuses')
    expect(all(".abstractor_abstractor_object_value")[3]).to be_nil
  end

  scenario 'Sorting a list of abstractor object values', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Anatomical location').first
    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end
    sleep(1)
    expect(all(".abstractor_abstractor_object_value")[0].find('.abstractor_object_value_value')).to have_content('abdomen, nos')
    expect(all(".abstractor_abstractor_object_value")[1].find('.abstractor_object_value_value')).to have_content('abdominal esophagus')
    expect(all(".abstractor_abstractor_object_value")[2].find('.abstractor_object_value_value')).to have_content('accessory sinus, nos')
    expect(all(".abstractor_abstractor_object_value")[3].find('.abstractor_object_value_value')).to have_content('accessory sinuses')
    expect(all(".abstractor_abstractor_object_value")[4].find('.abstractor_object_value_value')).to have_content('acoustic nerve')
    expect(all(".abstractor_abstractor_object_value")[5].find('.abstractor_object_value_value')).to have_content('adrenal gland')
    expect(all(".abstractor_abstractor_object_value")[6].find('.abstractor_object_value_value')).to have_content('adrenal gland, nos')
    expect(all(".abstractor_abstractor_object_value")[7].find('.abstractor_object_value_value')).to have_content('ampulla of vater')
    expect(all(".abstractor_abstractor_object_value")[8].find('.abstractor_object_value_value')).to have_content('anal canal')
    expect(all(".abstractor_abstractor_object_value")[9].find('.abstractor_object_value_value')).to have_content('anterior 2/3 of tongue, nos')

    click_link('Value')
    sleep(1)

    expect(all(".abstractor_abstractor_object_value")[0].find('.abstractor_object_value_value')).to have_content('waldeyer ring')
    expect(all(".abstractor_abstractor_object_value")[1].find('.abstractor_object_value_value')).to have_content('vulva, nos')
    expect(all(".abstractor_abstractor_object_value")[2].find('.abstractor_object_value_value')).to have_content('vulva')
    expect(all(".abstractor_abstractor_object_value")[3].find('.abstractor_object_value_value')).to have_content('vestibule of mouth')
    expect(all(".abstractor_abstractor_object_value")[4].find('.abstractor_object_value_value')).to have_content('vertebral column')
    expect(all(".abstractor_abstractor_object_value")[5].find('.abstractor_object_value_value')).to have_content('ventricle, nos')
    expect(all(".abstractor_abstractor_object_value")[6].find('.abstractor_object_value_value')).to have_content('ventral surface of tongue, nos')
    expect(all(".abstractor_abstractor_object_value")[7].find('.abstractor_object_value_value')).to have_content('vallecula')
    expect(all(".abstractor_abstractor_object_value")[8].find('.abstractor_object_value_value')).to have_content('vagina, nos')
    expect(all(".abstractor_abstractor_object_value")[9].find('.abstractor_object_value_value')).to have_content('vagina')

    click_link('Vocabulary Code')
    sleep(1)
    expect(all(".abstractor_abstractor_object_value")[0].find('.abstractor_object_value_vocabulary_code')).to have_content('C00')
    expect(all(".abstractor_abstractor_object_value")[1].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.0')
    expect(all(".abstractor_abstractor_object_value")[2].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.1')
    expect(all(".abstractor_abstractor_object_value")[3].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.2')
    expect(all(".abstractor_abstractor_object_value")[4].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.3')
    expect(all(".abstractor_abstractor_object_value")[5].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.4')
    expect(all(".abstractor_abstractor_object_value")[6].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.5')
    expect(all(".abstractor_abstractor_object_value")[7].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.6')
    expect(all(".abstractor_abstractor_object_value")[8].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.8')
    expect(all(".abstractor_abstractor_object_value")[9].find('.abstractor_object_value_vocabulary_code')).to have_content('C00.9')

    click_link('Vocabulary Code')
    sleep(1)
    expect(all(".abstractor_abstractor_object_value")[0].find('.abstractor_object_value_vocabulary_code')).to have_content('C80.9')
    expect(all(".abstractor_abstractor_object_value")[1].find('.abstractor_object_value_vocabulary_code')).to have_content('C80')
    expect(all(".abstractor_abstractor_object_value")[2].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.9')
    expect(all(".abstractor_abstractor_object_value")[3].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.8')
    expect(all(".abstractor_abstractor_object_value")[4].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.5')
    expect(all(".abstractor_abstractor_object_value")[5].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.4')
    expect(all(".abstractor_abstractor_object_value")[6].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.3')
    expect(all(".abstractor_abstractor_object_value")[7].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.2')
    expect(all(".abstractor_abstractor_object_value")[8].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.1')
    expect(all(".abstractor_abstractor_object_value")[9].find('.abstractor_object_value_vocabulary_code')).to have_content('C77.0')
  end
end