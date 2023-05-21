require 'rails_helper'
RSpec.feature 'Editing radiation therapy prescription: User should be able to edit radiation therapy prescription information', type: :system do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.radiation_therapy_prescription
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @pii_name = FactoryGirl.create(:pii_name, person_id: @person.person_id)
    FactoryGirl.create(:concept, concept_id: 10, concept_name: 'Procedure', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:concept, concept_id: 5085, concept_name: 'Note', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:concept, concept_id: 44818790, concept_name: 'Has procedure context (SNOMED)', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_RELATIONSHIP, concept_class_id: Concept::CONCEPT_CLASS_RELATIONSHIP, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    FactoryGirl.create(:relationship, relationship_id: 'Has proc context', relationship_name: 'Has procedure context (SNOMED)', is_hierarchical: 0, defines_ancestry: 0, reverse_relationship_id: 'Proc context of', relationship_concept_id: 44818790)
    @abstractor_namespace_radiation_therapy_prescription = Abstractor::AbstractorNamespace.where(name: 'Radiation Therapy Prescription', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first
  end

  scenario 'Editing an abstraction with radio button list', js: true, focus: false do
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    sleep(1)
    within('.has_laterality') do
      click_link('Edit')
    end
    expect(find('.has_laterality')).to have_content('bilateral')

    sleep(1)
    within('.has_laterality') do
      choose('left', allow_label_click: true)
    end
    click_button('Save')

    within(".has_laterality") do
      expect(page).to have_checked_field('left', visible: false)
    end

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page

    within(".has_laterality") do
      expect(page).to have_checked_field('left', visible: false)
    end

    delete_object_value_for_the_abstraction_schema("bilateral", "has_laterality")
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page

    within('.has_laterality') do
      click_link('Edit')
    end
    expect(find('.has_laterality')).to_not have_content('bilateral')
  end

  scenario 'Adding and removing abstraction groups', js: true, focus: false do
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(page).to_not have_content('DELETE ANATOMICAL LOCATION')
    expect(page).to have_content('ADD ANATOMICAL LOCATION')
    accept_confirm do
      click_link('Add Anatomical Location')
    end
    sleep(1)
    expect(all('.has_anatomical_location').size).to eq(2)
    expect(page).to have_content('DELETE ANATOMICAL LOCATION')
    expect(all('.has_anatomical_location')[1]).to have_content('unknown')

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    expect(page).to have_content('DELETE ANATOMICAL LOCATION')
    expect(all('.has_anatomical_location')[1]).to have_content('unknown')
    accept_confirm do
      click_link('Delete Anatomical Location')
    end
    sleep(1)
    expect(all('.has_anatomical_location').size).to eq(1)
    expect(all('.has_anatomical_location')[0]).to have_content('unknown')
    expect(page).to have_content('ADD ANATOMICAL LOCATION')
  end

  scenario 'Viewing abstraction groups with no suggestions', js: true, focus: false do
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(page).to have_content('Anatomical Location')
    expect(all('.has_anatomical_location')[0]).to have_content('Edit')
    expect(page).to have_content('ADD ANATOMICAL LOCATION')
    expect(page).to_not have_content('Delete Anatomical Location')
    expect(all('.has_anatomical_location')[0]).to have_content('unknown')
  end

  scenario 'Viewing abstraction groups with suggestions', js: true, focus: false do
    note_text = "right temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(page).to have_content('Anatomical Location')
    within(".has_anatomical_location") do
      expect(page).to have_unchecked_field('temporal lobe', visible: false)
    end
    expect(all('.has_anatomical_location')[0]).to have_content('Edit')
    expect(page).to have_content('ADD ANATOMICAL LOCATION')
    expect(page).to_not have_content('DELETE ANATOMICAL LOCATION')
  end

  scenario 'Adding abstraction groups to abstraction groups with suggestions', js: true, focus: false do
    note_text = "treat the temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_abstraction_group .has_anatomical_location').size).to eq(1)
    accept_confirm do
      click_link('Add Anatomical Location')
    end
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_abstraction_group .has_anatomical_location').size).to eq(2)
    expect(all('.abstractor_abstraction_group .abstractor_abstraction_actions')[0]).to have_content('NOT APPLICABLE GROUP')
    expect(all('.abstractor_abstraction_group .abstractor_abstraction_actions')[0]).to have_content('UNKNOWN GROUP')
    sleep(1)
    expect(all('.has_anatomical_location')[0]).to have_unchecked_field('temporal lobe', visible: false)
    expect(all('.has_anatomical_location')[1]).to have_unchecked_field('temporal lobe', visible: false)
  end

  scenario 'User setting the value of an abstraction schema with a date object type in a group', js: true, focus: false do
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)

    all('.has_radiation_therapy_prescription_date')[0].find('a.edit_link').click

    within('.has_radiation_therapy_prescription_date') do
      fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    end
    click_button('Save')
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', visible: false)
  end

  scenario "User setting all the values to 'not applicable' in an abstraction group", js: true, focus: false do
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)

    expect(all('.has_anatomical_location')[0]).to have_content('unknown')
    expect(all('.has_laterality')[0]).to have_content('unknown')
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_content('unknown')

    accept_confirm do
      all('.abstractor_abstraction_group')[0].find('a.abstractor_group_not_applicable_all_link').click
    end
    sleep(1)
    expect(all('.has_anatomical_location')[0]).to have_checked_field('not applicable', visible: false)
    expect(all('.has_laterality')[0]).to have_checked_field('not applicable', visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('not applicable', visible: false)
  end

  scenario "User setting all the values to 'unknown' in an abstraction group", js: true, focus: false do
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)

    expect(all('.has_anatomical_location')[0]).to have_content('unknown')
    expect(all('.has_laterality')[0]).to have_content('unknown')
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_content('unknown')

    accept_confirm do
      all('.abstractor_abstraction_group')[0].find('a.abstractor_group_unknown_all_link').click
    end
    sleep(1)
    expect(all('.has_anatomical_location')[0]).to have_content('unknown')
    expect(all('.has_laterality')[0]).to have_content('unknown')
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_content('unknown')
  end

  #mgurley Come Back To Me
  scenario 'Updating the workflowstatus of a group', js: true, focus: false  do
    workflow_status_is_enabled("Anatomical Location", "Submit", "Remove")
    note_text = "right temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0].find('.abstractor_group_update_workflow_status_link_submit')).to be_truthy
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: true)
    all('.has_anatomical_location')[0].check('temporal lobe', allow_label_click: true)
    all('.has_laterality')[0].check('right', allow_label_click: true)
    all('.has_radiation_therapy_prescription_date')[0].click_link('Edit')
    all('.has_radiation_therapy_prescription_date')[0].fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    click_button('Save')
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    all('.has_anatomical_location')[0].click_link('Clear')
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: true)
    all('.has_anatomical_location')[0].check('temporal lobe', allow_label_click: true)
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    all('.has_anatomical_location')[0].uncheck('temporal lobe', allow_label_click: true)
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: true)
    all('.has_anatomical_location')[0].check('temporal lobe', allow_label_click: true)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)

    accept_confirm do
      all('.abstractor_abstraction_group')[0].click_button('Submit')
    end

    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Submit')
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Remove', disabled: false)
    sleep(1)
    expect(all('.has_anatomical_location')[0]).to have_checked_field('temporal lobe', visible: false, disabled: true)
    expect(all('.has_laterality')[0]).to have_checked_field('right', visible: false, disabled: true)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', visible: false, disabled: true)

    accept_confirm do
      all('.abstractor_abstraction_group')[0].click_button('Remove')
    end
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Remove')
    sleep(1)
    accept_confirm do
      all('.abstractor_abstraction_group')[0].click_button('Submit')
    end
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Submit')
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Remove', disabled: false)
    sleep(1)
    expect(all('.has_anatomical_location')[0]).to have_checked_field('temporal lobe', visible: false, disabled: true)
    expect(all('.has_laterality')[0]).to have_checked_field('right', visible: false, disabled: true)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', visible: false, disabled: true)
    sleep(1)
    accept_confirm do
      all('.abstractor_subject_groups_container')[0].click_link('Add Anatomical Location')
    end
    sleep(1)
    scroll_to_bottom_of_the_page

    expect(all('.abstraction_workflow_status_form')[1]).to have_button('Submit', disabled: true)
    expect(all('.abstraction_workflow_status_form')[1]).to_not have_button('Remove')
  end

  scenario 'Removing the workflowstatus of a radiation therapy when it is not fully set', js: true, focus: false do
    workflow_status_is_enabled("Anatomical Location", "Submit", "Remove")
    note_text = "right temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    all('.has_anatomical_location')[0].check('temporal lobe', allow_label_click: true)
    all('.has_laterality')[0].check('right', allow_label_click: true)
    all('.has_radiation_therapy_prescription_date')[0].click_link('Edit')
    sleep(1)
    all('.has_radiation_therapy_prescription_date')[0].fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    click_button('Save')
    sleep(1)
    accept_confirm do
      all('.abstractor_abstraction_group')[0].click_button('Submit')
    end
    note_stable_identifier.abstractor_abstractions.first.abstractor_suggestions.each do |abstractor_suggestion|
      abstractor_suggestion.accepted = false
      abstractor_suggestion.save!
    end
    note_text = "right temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: true)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Remove')
  end

  scenario 'User editing an abstraction for a fully set radiation therapy prescription', js: true, focus: false do
    workflow_status_is_enabled("Anatomical Location", "Submit", "Remove")
    note_text = "right temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    all('.has_anatomical_location')[0].check('temporal lobe', allow_label_click: true)
    all('.has_laterality')[0].check('right', allow_label_click: true)
    all('.has_radiation_therapy_prescription_date')[0].click_link('Edit')
    sleep(1)
    all('.has_radiation_therapy_prescription_date')[0].fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    click_button('Save')
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Remove')

    all('.has_radiation_therapy_prescription_date')[0].click_link('Edit')
    sleep(1)

    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: true)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Remove')
  end

  scenario 'Submitting and discarding across an entire radiation therapy prescription', js: true, focus: false do
    workflow_status_is_enabled("Anatomical Location", "Submit", "Remove")
    note_text = "right temporal lobe"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: true)
    expect(all('.abstractor_abstraction_group')[0]).to_not have_button('Remove')
    expect(all('a.abstractor_group_add_link', text: 'ADD ANATOMICAL LOCATION').size).to eq(1)
    accept_confirm do
      click_link('Add Anatomical Location')
    end
    sleep(1)
    all('.has_anatomical_location')[0].check('temporal lobe', allow_label_click: true)
    all('.has_laterality')[0].check('right', allow_label_click: true)
    all('.has_radiation_therapy_prescription_date')[0].click_link('Edit')
    sleep(1)
    all('.has_radiation_therapy_prescription_date')[0].fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    click_button('Save')
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    expect(all('.abstractor_abstraction_group')[1]).to have_button('Submit', disabled: true)

    all('.has_anatomical_location')[1].check('temporal lobe', allow_label_click: true)
    all('.has_laterality')[1].check('right', allow_label_click: true)
    all('.has_radiation_therapy_prescription_date')[1].click_link('Edit')
    sleep(1)
    all('.has_radiation_therapy_prescription_date')[1].fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    click_button('Save')
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    expect(all('.abstractor_abstraction_group')[1]).to have_button('Submit', disabled: false)
    expect(all('.abstractor_subject_groups_container')[0].find('a.abstractor_group_add_link', text: 'ADD ANATOMICAL LOCATION')).to be_truthy
    sleep(1)

    accept_confirm do
      all('.abstraction_workflow_status_form')[0].find('input.abstractor_group_update_workflow_status_link_submit').click
    end
    sleep(1)

    accept_confirm do
      all('.abstraction_workflow_status_form')[1].find('input.abstractor_group_update_workflow_status_link_submit').click
    end
    sleep(1)
    expect(all('.abstractor_abstraction_group')[0]).to have_button('Remove', disabled: false)
    expect(all('.abstractor_abstraction_group')[1]).to have_button('Remove', disabled: false)
    expect(all('.workflow_status_pending').size).to eq(0)
    expect(all('.workflow_status_submitted').size).to eq(2)
    expect(all('.workflow_status_discarded').size).to eq(0)

    sleep(1)
    expect(note_stable_identifier.reload.submitted?).to be_truthy
    expect(note_stable_identifier.discarded?).to be_falsy

    expect(all('.has_anatomical_location')[0]).to have_checked_field('temporal lobe', disabled: true, visible: false)
    expect(all('.has_laterality')[0]).to have_checked_field('right', disabled: true, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', disabled: true, visible: false)

    expect(all('.has_anatomical_location')[1]).to have_checked_field('temporal lobe', disabled: true, visible: false)
    expect(all('.has_laterality')[1]).to have_checked_field('right', disabled: true, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[1]).to have_checked_field('2014-06-03', disabled: true, visible: false)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page
    sleep(1)

    expect(all('a.abstractor_group_add_link', text: 'Add Anatomical Location').size).to eq(0)

    accept_confirm do
      all('.abstractor_abstraction_group_actions')[0].click_button('Remove')
    end

    sleep(1)

    expect(all('.abstractor_abstraction_group')[0]).to have_button('Submit', disabled: false)
    expect(all('.workflow_status_pending').size).to eq(1)
    expect(all('.workflow_status_submitted').size).to eq(1)
    expect(all('.workflow_status_discarded').size).to eq(0)

    expect(note_stable_identifier.reload.submitted?).to be_falsy
    expect(note_stable_identifier.discarded?).to be_falsy

    expect(all('.has_anatomical_location')[0]).to have_checked_field('temporal lobe', disabled: false, visible: false)
    expect(all('.has_laterality')[0]).to have_checked_field('right', disabled: false, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', disabled: false, visible: false)
    expect(all('.has_anatomical_location')[1]).to have_checked_field('temporal lobe', disabled: true, visible: false)
    expect(all('.has_laterality')[1]).to have_checked_field('right', disabled: true, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[1]).to have_checked_field('2014-06-03', disabled: true, visible: false)

    accept_confirm do
      all('.abstractor_abstraction_group_actions')[1].click_button('Remove')
    end

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page
    sleep(1)

    expect(all('.abstractor_subject_groups_container')[0].find('a.abstractor_group_add_link', text: 'ADD ANATOMICAL LOCATION')).to be_truthy
    sleep(1)

    accept_confirm do
      all('.abstraction_workflow_status_form')[0].find('input.abstractor_group_update_workflow_status_link_submit').click
    end
    sleep(1)

    accept_confirm do
      all('.abstraction_workflow_status_form')[1].find('input.abstractor_group_update_workflow_status_link_submit').click
    end
    sleep(1)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page
    sleep(1)

    accept_confirm do
      all('.note_actions')[0].click_link('Discard')
    end
    sleep(1)

    expect(note_stable_identifier.reload.submitted?).to be_falsy
    expect(note_stable_identifier.discarded?).to be_truthy

    expect(all('.workflow_status_pending').size).to eq(0)
    expect(all('.workflow_status_submitted').size).to eq(0)
    expect(all('.workflow_status_discarded').size).to eq(2)

    expect(all('.has_anatomical_location')[0]).to have_checked_field('temporal lobe', disabled: true, visible: false)
    expect(all('.has_laterality')[0]).to have_checked_field('right', disabled: true, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', disabled: true, visible: false)
    expect(all('.has_anatomical_location')[1]).to have_checked_field('temporal lobe', disabled: true, visible: false)
    expect(all('.has_laterality')[1]).to have_checked_field('right', disabled: true, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[1]).to have_checked_field('2014-06-03', disabled: true, visible: false)
    expect(all('a.abstractor_group_add_link', text: 'ADD ANATOMICAL LOCATION').size).to eq(0)

    accept_confirm do
      all('.note_actions')[0].click_link('Undiscard')
    end
    sleep(1)

    expect(note_stable_identifier.reload.submitted?).to be_falsy
    expect(note_stable_identifier.discarded?).to be_falsy

    expect(all('.workflow_status_pending').size).to eq(2)
    expect(all('.workflow_status_submitted').size).to eq(0)
    expect(all('.workflow_status_discarded').size).to eq(0)

    expect(all('.has_anatomical_location')[0]).to have_checked_field('temporal lobe', disabled: false, visible: false)
    expect(all('.has_laterality')[0]).to have_checked_field('right', disabled: false, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[0]).to have_checked_field('2014-06-03', disabled: false, visible: false)
    expect(all('.has_anatomical_location')[1]).to have_checked_field('temporal lobe', disabled: false, visible: false)
    expect(all('.has_laterality')[1]).to have_checked_field('right', disabled: false, visible: false)
    expect(all('.has_radiation_therapy_prescription_date')[1]).to have_checked_field('2014-06-03', disabled: false, visible: false)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(all('a.abstractor_group_add_link', text: 'ADD ANATOMICAL LOCATION').size).to eq(1)
  end

  scenario 'Autocompleter filtering', js: true, focus: false do
    pending "Expected to fail: Need to migrate to an autocompleter."
    workflow_status_is_enabled("Anatomical Location", "Submit", "Remove")
    note_text = "Vague blather."
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_radiation_therapy_prescription.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)

    all('.has_anatomical_location')[0].click_link('Edit')
    sleep(1)

    diagnosis = 'mouth'
    find('div.select-wrapper input').click #open the dropdown
    find('div.select-wrapper li', text: diagnosis).click #select the option wanted

    expect(find("ul.ui-autocomplete", text: 'anterior floor of mouth')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'floor of mouth')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'floor of mouth, nos')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'lateral floor of mouth')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'mouth, nos')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'other and unspecified parts of mouth')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'overlapping lesion of floor of mouth')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'overlapping lesion of other and unspecified parts of mouth')).to be_truthy
    expect(find("ul.ui-autocomplete", text: 'vestibule of mouth')).to be_truthy
  end
end

def delete_object_value_for_the_abstraction_schema(value, abstraction_schema_predicate)
  abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(predicate: abstraction_schema_predicate).first
  abstractor_abstraction_schema.abstractor_object_values.where(value: value).first.destroy
end

def workflow_status_is_enabled(abstractor_subject_group_name, submit_label, pend_label)
  abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: abstractor_subject_group_name).first
  abstractor_subject_group.enable_workflow_status = true
  abstractor_subject_group.workflow_status_submit = submit_label
  abstractor_subject_group.workflow_status_pend = pend_label
  abstractor_subject_group.save!
end

def workflow_status_is_not_enabled(abstractor_subject_group_name)
  abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: abstractor_subject_group_name).first
  abstractor_subject_group.enable_workflow_status = false
  abstractor_subject_group.save!
end