require 'rails_helper'
RSpec.feature 'Editing surgery: User should be able to edit surgery information', type: :system do
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

  scenario 'User editing an abstraction with indirect sources', js: true, focus: false do
    pending "Expected to fail: Need to figure out if we want to support indirect sources."
    create_surgical_procedures([{'Surgery Case ID' => 100, 'Description' => 'Left temporal lobe resection',  'Modifier' => 'Left' }, { 'Surgery Case ID' => 100, 'Description' => 'Insert shunt',  'Modifier' => 'Left' }])
    create_surgeries([ { 'Surgery Case ID' => 100, 'Surgery Case Number' => 'OR-123',  'Patient ID' => 1 }])
    create_imaging_exams(
    [{'Note Text' => "Hello, you look good to me.", 'Patient ID' => 1, 'Date' => '1/1/2014', 'Accession Number' => '123' },
    {'Note Text' => "Hello, you look suspicious.", 'Patient ID' => 1, 'Date' => '2/1/2014', 'Accession Number' => '456' },
    {'Note Text' => "Hello, you look better than before.", 'Patient ID' => 2, 'Date' => '5/1/2014', 'Accession Number' => '789' }])
    create_surgical_procedure_reports(
    [{'Note Text' => "Surgery went well.", 'Patient ID' => 1, 'Date' => '1/1/2013', 'Reference Number' => '111' },
    {'Note Text' => "Surgery went not so well.", 'Patient ID' => 1, 'Date' => '2/1/2013', 'Reference Number' => '222' },
    {'Note Text' => "Hello, you look better than before.", 'Patient ID' => 2, 'Date' => '5/1/2013', 'Reference Number' => '333' }])

    @abstractable = Surgery.last
    visit(edit_surgery_path(@abstractable))

    within('.has_imaging_confirmed_extent_of_resection') do
      click_link('Edit')
    end
    sleep(1)
    all('.indirect_source', text: 'Indirect Source: Imaging exam')[0].find('.indirect_source_list').select("123 (2014-01-01)")
    sleep(1)
    expect(all('.indirect_source', text: 'Indirect Source: Imaging exam')[0].find('.indirect_source_text')).to have_content("Hello, you look good to me.")

    imaging_confirmed_extent_of_resection = 'Gross total resection'
    find('.custom-combobox-input').send_keys(imaging_confirmed_extent_of_resection)
    find("ul.ui-autocomplete li.ui-menu-item", text: imaging_confirmed_extent_of_resection).click()

    click_button('Save')
    sleep(1)
    visit(edit_surgery_path(@abstractable))
    sleep(1)
    within('.has_imaging_confirmed_extent_of_resection') do
      click_link('Edit')
    end
    sleep(1)
    imaging_exam = ImagingExam.where(accession_number: '123').first
    expect(all('.indirect_source', text: 'Indirect Source: Imaging exam')[0]).to have_css(%{select.indirect_source_list option[selected="selected"][value="#{imaging_exam.id}"]})
    visit(edit_surgery_path(@abstractable))
    sleep(1)
    click_link('Add Surgery Anatomical Location')
    sleep(1)
    all('.has_imaging_confirmed_extent_of_resection')[1].click_link('Edit')
    sleep(1)
    all('.indirect_source', text: 'Indirect Source: Imaging exam')[0].find('.indirect_source_list').select("456 (2014-01-02)")
    sleep(1)
    expect(all('.indirect_source', text: 'Indirect Source: Imaging exam')[0].find('.indirect_source_text')).to have_content("Hello, you look suspicious.")

    imaging_confirmed_extent_of_resection = 'Gross total resection'
    find('.custom-combobox-input').send_keys(imaging_confirmed_extent_of_resection)
    find("ul.ui-autocomplete li.ui-menu-item", text: imaging_confirmed_extent_of_resection).click()

    click_button('Save')
    sleep(1)
    visit(edit_surgery_path(@abstractable))
    all('.has_imaging_confirmed_extent_of_resection')[1].click_link('Edit')
    imaging_exam = ImagingExam.where(accession_number: '456').first
    expect(all('.indirect_source', text: 'Indirect Source: Imaging exam')[0]).to have_css(%{select.indirect_source_list option[selected="selected"][value="#{imaging_exam.id}"]})
  end

  scenario 'User editing an abstraction with a suggestion against a complex source', js: true, focus: false do
    pending "Expected to fail: Need to figure out if we want to support complex sources."
    create_surgical_procedures([{'Surgery Case ID' => 100, 'Description' => 'Left temporal lobe resection',  'Modifier' => 'Left' }, { 'Surgery Case ID' => 100, 'Description' => 'Insert shunt',  'Modifier' => 'Left' }])
    create_surgeries([ { 'Surgery Case ID' => 100, 'Surgery Case Number' => 'OR-123',  'Patient ID' => 1 }])
    create_imaging_exams(
    [{'Note Text' => "Hello, you look good to me.", 'Patient ID' => 1, 'Date' => '1/1/2014', 'Accession Number' => '123' },
    {'Note Text' => "Hello, you look suspicious.", 'Patient ID' => 1, 'Date' => '2/1/2014', 'Accession Number' => '456' },
    {'Note Text' => "Hello, you look better than before.", 'Patient ID' => 2, 'Date' => '5/1/2014', 'Accession Number' => '789' }])
    create_surgical_procedure_reports(
    [{'Note Text' => "Surgery went well.", 'Patient ID' => 1, 'Date' => '1/1/2013', 'Reference Number' => '111' },
    {'Note Text' => "Surgery went not so well.", 'Patient ID' => 1, 'Date' => '2/1/2013', 'Reference Number' => '222' },
    {'Note Text' => "Hello, you look better than before.", 'Patient ID' => 2, 'Date' => '5/1/2013', 'Reference Number' => '333' }])

    @abstractable = Surgery.last
    visit(edit_surgery_path(@abstractable))
    sleep(1)
    find(:css, '.has_anatomical_location  span.abstractor_abstraction_source_tooltip_img').click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Surgical Procedure: Description')
    expect(find('.abstractor_source_tab_content')).to have_content('Left temporal lobe resection')
    match_highlighted_text('.abstractor_source_tab_content', 'temporal lobe')
    visit(edit_surgery_path(@abstractable))
    sleep(1)
    all('.has_imaging_confirmed_extent_of_resection')[0].click_link('Edit')
    #Then I should see 4 "span.abstractor_abstraction_source_tooltip_img" within the last ".edit_abstractor_abstraction"
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

def create_surgical_procedures(surgical_procedures)
  surgical_procedures.each_with_index do |surgical_procedure_hash, i|
    surgical_procedure = FactoryGirl.create(:surgical_procedure, surg_case_id: surgical_procedure_hash['Surgery Case ID'], description: surgical_procedure_hash['Description'], modifier: surgical_procedure_hash['Modifier'])
  end
end

# def create_imaging_exams(imaging_exams)
#   imaging_exams.each_with_index do |imaging_exam_hash, i|
#     imaging_exam = FactoryGirl.create(:imaging_exam, note_text: imaging_exam_hash['Note Text'], patient_id: imaging_exam_hash['Patient ID'], report_date: Date.parse(imaging_exam_hash['Date']), accession_number: imaging_exam_hash['Accession Number'])
#     imaging_exam.abstract(namespace_type: imaging_exam_hash['Namespace'], namespace_id: imaging_exam_hash['Namespace ID'].to_i)
#   end
# end

def create_surgical_procedure_reports(surgical_procedure_reports)
  surgical_procedure_reports.each_with_index do |surgical_procedure_report_hash, i|
    surgical_procedure_report = FactoryGirl.create(:surgical_procedure_report, note_text: surgical_procedure_report_hash['Note Text'], patient_id: surgical_procedure_report_hash['Patient ID'], report_date: Date.parse(surgical_procedure_report_hash['Date']), reference_number: surgical_procedure_report_hash['Reference Number'])
  end
end