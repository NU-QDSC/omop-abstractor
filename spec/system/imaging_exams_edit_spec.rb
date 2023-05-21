require 'rails_helper'
RSpec.feature 'Editing imaging exam: User should be able to edit namespaced imaging exam information', type: :system do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.imaging_exam
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @pii_name = FactoryGirl.create(:pii_name, person_id: @person.person_id)
    FactoryGirl.create(:concept, concept_id: 10, concept_name: 'Procedure', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:concept, concept_id: 5085, concept_name: 'Note', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:concept, concept_id: 44818790, concept_name: 'Has procedure context (SNOMED)', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_RELATIONSHIP, concept_class_id: Concept::CONCEPT_CLASS_RELATIONSHIP, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:relationship, relationship_id: 'Has proc context', relationship_name: 'Has procedure context (SNOMED)', is_hierarchical: 0, defines_ancestry: 0, reverse_relationship_id: 'Proc context of', relationship_concept_id: 44818790)
    @abstractor_namespace_imaging_exams_1 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 1').first
    @abstractor_namespace_imaging_exams_2 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 2').first
    @abstractor_namespace_imaging_exams_3 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 3').first
  end

  scenario 'Editing abstractions in one namespace', js: true, focus: false do
    create_imaging_exams([{'Note Text' => 'Hello, you look good to me.', 'Date' => '1/1/2014', 'Namespace' => Abstractor::AbstractorNamespace.to_s, 'Namespace ID' => @abstractor_namespace_imaging_exams_1.id}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    expect(find('.has_dopamine_transporter_level ')).to have_content('Dopamine transporter level')
    expect(find('.has_anatomical_location')).to have_content('Anatomical location')
    expect(find('.has_diagnosis')).to have_content('Diagnosis')
    expect(page).to_not have_content('RECIST response criteria')
    expect(page).to_not have_content('Favorite minor Moomin character')
  end

  scenario 'Editing abstractions in another namespace', js: true, focus: false do
    create_imaging_exams([{'Note Text' => 'Hello, you look good to me.', 'Date' => '1/1/2014', 'Namespace' => Abstractor::AbstractorNamespace.to_s, 'Namespace ID' => @abstractor_namespace_imaging_exams_2.id}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_recist_response_criteria')).to have_content('RECIST response criteria')
    expect(find('.has_anatomical_location')).to have_content('Anatomical location')
    expect(find('.has_favorite_minor_moomin_character')).to have_content('Favorite minor Moomin character')
    expect(page).to_not have_content('Dopamine transporter level')
    expect(page).to_not have_content('Favorite major Moomin character')
  end

  scenario 'Editing abstractions on an imaging exam in multiple namespaces', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'Hello, you look good to me.', note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_recist_response_criteria')).to have_content('RECIST response criteria')
    expect(find('.has_anatomical_location')).to have_content('Anatomical location')
    expect(find('.has_favorite_minor_moomin_character')).to have_content('Favorite minor Moomin character')
    expect(page).to_not have_content('Dopamine transporter level')
    expect(page).to_not have_content('Favorite major Moomin character')
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    scroll_to_bottom_of_the_page
    expect(find('.has_dopamine_transporter_level ')).to have_content('Dopamine transporter level')
    expect(find('.has_anatomical_location')).to have_content('Anatomical location')
    expect(find('.has_diagnosis')).to have_content('Diagnosis')
    expect(page).to_not have_content('RECIST response criteria')
    expect(page).to_not have_content('Favorite minor Moomin character')
  end

  scenario 'Groups displayed in UI should maintain namespace', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'Hello, you look good to me.', note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_subject_groups_container')[1].all('.has_diagnosis').size).to eq(1)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id))
    sleep(1)
    expect(all('.abstractor_subject_groups_container')[1].all('.has_diagnosis').size).to eq(0)
  end

  scenario 'Groups displayed in UI should contain only abstractions related to selected namespace', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'Hello, you look good to me.', note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_subject_groups_container')[0].all('.has_dopamine_transporter_level').size).to eq(1)
    @abstractor_namespace_imaging_exams_2 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 2').first
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id))
    sleep(1)
    expect(all('.abstractor_subject_groups_container')[0].all('.has_dopamine_transporter_level').size).to eq(0)
  end

  scenario 'Adding groups in UI should add only abstractions related to selected namespace', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'Hello, you look good to me.', note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    accept_confirm do
      click_link('Add Diagnosis')
    end
    sleep(1)
    scroll_to_bottom_of_the_page
    expect(all('.abstractor_subject_groups_container')[1].all('.has_diagnosis').size).to eq(2)
    expect(all('.abstractor_subject_groups_container')[1]).to have_content('DELETE DIAGNOSIS')
  end

  scenario 'Editing groups in UI should edit only abstractions related to selected namespace', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'Hello, you look good to me.', note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    accept_confirm do
      click_link('Add Diagnosis')
    end
    sleep(1)
    all('.has_diagnosis')[1].find(:css, '.edit_link').click
    sleep(1)
    scroll_to_bottom_of_the_page
    diagnosis = 'Ataxia'
    find('div.select-wrapper input').click #open the dropdown
    find('div.select-wrapper li', text: diagnosis).click #select the option wanted
    click_button('Save')
    sleep(1)
    expect(all('.has_diagnosis')[1]).to have_checked_field(diagnosis, visible: false)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    sleep(1)
    expect(all('.has_diagnosis')[1]).to have_checked_field(diagnosis, visible: false)
    @abstractor_namespace_imaging_exams_2 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 2').first
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id))
    expect(all('.has_diagnosis').size).to eq(0)
  end

  scenario 'Adding groups in UI should respect group cardinality', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'Hello, you look good to me.', note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_3.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_3.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.has_score_1')[0]).to have_content('Score 1')
    expect(all('.has_falls')[0]).to have_content('Falls')
    expect(all('.abstractor_subject_groups_container')[0]).to have_content('ADD SCORES')
    accept_confirm do
      click_link('Add Scores')
    end
    sleep(1)
    expect(all('.has_score_1').size).to eq(2)
    expect(all('.abstractor_subject_groups_container')[1]).to_not have_content('ADD SCORES')
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_3.id))
    sleep(1)
    expect(all('.abstractor_subject_groups_container')[0].all('.has_score_1').size).to eq(2)
    expect(all('.abstractor_subject_groups_container')[0]).to_not have_content('ADD SCORES')
    accept_confirm do
      click_link('Delete Scores')
    end
    sleep(1)
    expect(all('.abstractor_subject_groups_container')[0]).to have_content('ADD SCORES')
    expect(all('.abstractor_subject_groups_container')[0].all('.has_score_1').size).to eq(1)
  end

  scenario 'New group of abstractions displays valid sources', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: "I like little my the best!\nfavorite moomin:\nThe groke is the bomb!", note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    accept_confirm do
      click_link('Add Diagnosis')
    end
    sleep(1)
    all('.has_favorite_major_moomin_character span.abstractor_abstraction_source_tooltip_img')[0].click
    sleep(1)
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab')[0]).to have_content('The groke is the bomb!')
  end
end

def create_imaging_exams(imaging_exams)
  imaging_exams.each_with_index do |imaging_exam_hash, i|
    note = FactoryGirl.create(:note, person: @person, note_text: imaging_exam_hash['Note Text'], note_date: Date.parse(imaging_exam_hash['Date']))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: imaging_exam_hash['Namespace'], namespace_id: imaging_exam_hash['Namespace ID'].to_i)
  end
end