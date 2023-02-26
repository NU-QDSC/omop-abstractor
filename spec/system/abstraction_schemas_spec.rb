require 'rails_helper'
RSpec.feature 'Abstractor Schemas', type: :system do
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

  scenario 'Viewing a list of abstraction schemas', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Anatomical location')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Date Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Diagnosis')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Dopamine transporter level')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Duration')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Extent of resection')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Falls')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Favorite major Moomin character')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Favorite minor Moomin character')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Freezing')


    abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(display_name: 'Falls').first

    within("#abstractor_abstractor_abstraction_schema_#{abstractor_abstraction_schema.id}") do
      click_link('Values')
    end
    expect(page.current_path).to eq(abstractor_abstraction_schema_abstractor_object_values_path(abstractor_abstraction_schema))

    visit abstractor_abstraction_schemas_path
    sleep(1)

    all('.abstractor_abstraction_schemas_list .pagination a', text: '2')[0].click
    sleep(1)

    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Karnofsky performance status')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Karnofsky performance status date')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Laterality')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Numeric Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'RECIST response criteria')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Radiation therapy prescription date')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Score 1')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Score 2')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'String Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Surgery')

    all('.abstractor_abstraction_schemas_list .pagination a', text: '3')[0].click
    sleep(1)
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Text Schema')

    visit abstractor_abstraction_schemas_path

    find('.abstractor_abstraction_schemas_list th a', text: 'Name').click
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Text Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Surgery')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'String Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Score 2')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Score 1')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Radiation therapy prescription date')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'RECIST response criteria')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Numeric Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Laterality')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Karnofsky performance status date')
  end

  scenario 'Searching a list of abstraction schemas', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')

    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Anatomical location')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Date Schema')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Diagnosis')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Dopamine transporter level')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Duration')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Extent of resection')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Falls')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Favorite major Moomin character')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Favorite minor Moomin character')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Freezing')

    fill_in 'Search', with: 'Favorite'
    click_button('Search')

    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Anatomical location')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Date Schema')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Diagnosis')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Dopamine transporter level')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Duration')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Extent of resection')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Falls')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Favorite major Moomin character')
    expect(page).to have_css('.abstractor_abstraction_schema_display_name', text: 'Favorite minor Moomin character')
    expect(page).to_not have_css('.abstractor_abstraction_schema_display_name', text: 'Freezing')
  end

  scenario 'Sorting a list of abstraction schemas', js: true, focus: false do
    visit abstractor_abstraction_schemas_path
    logs_in('mjg994', 'secret')

    expect(all(".abstractor_abstractor_abstraction_schema")[0].find('.abstractor_abstraction_schema_display_name')).to have_content('Anatomical location')
    expect(all(".abstractor_abstractor_abstraction_schema")[1].find('.abstractor_abstraction_schema_display_name')).to have_content('Date Schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[2].find('.abstractor_abstraction_schema_display_name')).to have_content('Diagnosis')
    expect(all(".abstractor_abstractor_abstraction_schema")[3].find('.abstractor_abstraction_schema_display_name')).to have_content('Dopamine transporter level')
    expect(all(".abstractor_abstractor_abstraction_schema")[4].find('.abstractor_abstraction_schema_display_name')).to have_content('Duration')
    expect(all(".abstractor_abstractor_abstraction_schema")[5].find('.abstractor_abstraction_schema_display_name')).to have_content('Extent of resection')
    expect(all(".abstractor_abstractor_abstraction_schema")[6].find('.abstractor_abstraction_schema_display_name')).to have_content('Falls')
    expect(all(".abstractor_abstractor_abstraction_schema")[7].find('.abstractor_abstraction_schema_display_name')).to have_content('Favorite major Moomin character')
    expect(all(".abstractor_abstractor_abstraction_schema")[8].find('.abstractor_abstraction_schema_display_name')).to have_content('Favorite minor Moomin character')
    expect(all(".abstractor_abstractor_abstraction_schema")[9].find('.abstractor_abstraction_schema_display_name')).to have_content('Freezing')

    click_link('Name')
    sleep(1)

    expect(all(".abstractor_abstractor_abstraction_schema")[0].find('.abstractor_abstraction_schema_display_name')).to have_content('Text Schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[1].find('.abstractor_abstraction_schema_display_name')).to have_content('Surgery')
    expect(all(".abstractor_abstractor_abstraction_schema")[2].find('.abstractor_abstraction_schema_display_name')).to have_content('String Schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[3].find('.abstractor_abstraction_schema_display_name')).to have_content('Score 2')
    expect(all(".abstractor_abstractor_abstraction_schema")[4].find('.abstractor_abstraction_schema_display_name')).to have_content('Score 1')
    expect(all(".abstractor_abstractor_abstraction_schema")[5].find('.abstractor_abstraction_schema_display_name')).to have_content('Radiation therapy prescription date')
    expect(all(".abstractor_abstractor_abstraction_schema")[6].find('.abstractor_abstraction_schema_display_name')).to have_content('RECIST response criteria')
    expect(all(".abstractor_abstractor_abstraction_schema")[7].find('.abstractor_abstraction_schema_display_name')).to have_content('Numeric Schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[8].find('.abstractor_abstraction_schema_display_name')).to have_content('Laterality')
    expect(all(".abstractor_abstractor_abstraction_schema")[9].find('.abstractor_abstraction_schema_display_name')).to have_content('Karnofsky performance status date')

    click_link('Predicate')
    sleep(1)

    expect(all(".abstractor_abstractor_abstraction_schema")[0].find('.abstractor_abstraction_schema_predicate')).to have_content('has_anatomical_location')
    expect(all(".abstractor_abstractor_abstraction_schema")[1].find('.abstractor_abstraction_schema_predicate')).to have_content('has_date_schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[2].find('.abstractor_abstraction_schema_predicate')).to have_content('has_diagnosis')
    expect(all(".abstractor_abstractor_abstraction_schema")[3].find('.abstractor_abstraction_schema_predicate')).to have_content('has_diagnosis_duration')
    expect(all(".abstractor_abstractor_abstraction_schema")[4].find('.abstractor_abstraction_schema_predicate')).to have_content('has_dopamine_transporter_level')
    expect(all(".abstractor_abstractor_abstraction_schema")[5].find('.abstractor_abstraction_schema_predicate')).to have_content('has_falls')
    expect(all(".abstractor_abstractor_abstraction_schema")[6].find('.abstractor_abstraction_schema_predicate')).to have_content('has_favorite_major_moomin_character')
    expect(all(".abstractor_abstractor_abstraction_schema")[7].find('.abstractor_abstraction_schema_predicate')).to have_content('has_favorite_minor_moomin_character')
    expect(all(".abstractor_abstractor_abstraction_schema")[8].find('.abstractor_abstraction_schema_predicate')).to have_content('has_freezing')
    expect(all(".abstractor_abstractor_abstraction_schema")[9].find('.abstractor_abstraction_schema_predicate')).to have_content('has_imaging_confirmed_extent_of_resection')

    click_link('Predicate')
    sleep(1)

    expect(all(".abstractor_abstractor_abstraction_schema")[0].find('.abstractor_abstraction_schema_predicate')).to have_content('has_text_schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[1].find('.abstractor_abstraction_schema_predicate')).to have_content('has_surgery')
    expect(all(".abstractor_abstractor_abstraction_schema")[2].find('.abstractor_abstraction_schema_predicate')).to have_content('has_string_schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[3].find('.abstractor_abstraction_schema_predicate')).to have_content('has_score_2')
    expect(all(".abstractor_abstractor_abstraction_schema")[4].find('.abstractor_abstraction_schema_predicate')).to have_content('has_score_1')
    expect(all(".abstractor_abstractor_abstraction_schema")[5].find('.abstractor_abstraction_schema_predicate')).to have_content('has_recist_response_criteria')
    expect(all(".abstractor_abstractor_abstraction_schema")[6].find('.abstractor_abstraction_schema_predicate')).to have_content('has_radiation_therapy_prescription_date')
    expect(all(".abstractor_abstractor_abstraction_schema")[7].find('.abstractor_abstraction_schema_predicate')).to have_content('has_numeric_schema')
    expect(all(".abstractor_abstractor_abstraction_schema")[8].find('.abstractor_abstraction_schema_predicate')).to have_content('has_laterality')
    expect(all(".abstractor_abstractor_abstraction_schema")[9].find('.abstractor_abstraction_schema_predicate')).to have_content('has_karnofsky_performance_status_date')
  end
end