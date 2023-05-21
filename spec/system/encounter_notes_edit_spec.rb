require 'rails_helper'
RSpec.feature 'Editing encounter note', type: :system do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.encounter_note
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @pii_name = FactoryGirl.create(:pii_name, person_id: @person.person_id)
    @abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
    @concept_domain_procedure = FactoryGirl.create(:concept, concept_id: 10, concept_name: 'Procedure', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    @concept_domain_note = FactoryGirl.create(:concept, concept_id: 5085, concept_name: 'Note', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    @concept_domain_specimen = FactoryGirl.create(:concept, concept_id: 36, concept_name: 'Specimen', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_DOMAIN, concept_class_id: Concept::CONCEPT_CLASS_DOMAIN, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    @concept_relationship_has_procedure_context = FactoryGirl.create(:concept, concept_id: 44818790, concept_name: 'Has procedure context (SNOMED)', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_RELATIONSHIP, concept_class_id: Concept::CONCEPT_CLASS_RELATIONSHIP, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    @relationship_has_procedure_context = FactoryGirl.create(:relationship, relationship_id: 'Has proc context', relationship_name: 'Has procedure context (SNOMED)', is_hierarchical: 0, defines_ancestry: 0, reverse_relationship_id: 'Proc context of', relationship_concept_id: 44818790)
    @concept_relationship_procedure_context_of = FactoryGirl.create(:concept, concept_id: 44818888, concept_name: 'Procedure context of (SNOMED)', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_RELATIONSHIP, concept_class_id: Concept::CONCEPT_CLASS_RELATIONSHIP, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    @relationship_proc_context_of = FactoryGirl.create(:relationship, relationship_id: 'Proc context of', relationship_name: 'Procedure context of (SNOMED)', is_hierarchical: 0, defines_ancestry: 0, reverse_relationship_id: 'Has proc context', relationship_concept_id: 44818888)
    @concept_relationship_has_specimen = FactoryGirl.create(:concept, concept_id: 44818756, concept_name: 'Has specimen (SNOMED)', domain_id: Concept::DOMAIN_ID_METADATA, vocabulary_id: Concept::VOCABULARY_ID_RELATIONSHIP, concept_class_id: Concept::CONCEPT_CLASS_RELATIONSHIP, concept_code: Concept::CONCEPT_CODE_OMOP_GENERATED)
    @relationship_has_specimen = FactoryGirl.create(:relationship, relationship_id: 'Has specimen', relationship_name: 'Has specimen (SNOMED)', is_hierarchical: 0, defines_ancestry: 0, reverse_relationship_id: 'Has proc context', relationship_concept_id: 44818756)
  end

  scenario 'Viewing an abstraction with an actual suggestion', js: true, focus: false do
    [{'Note Text' => 'Looking good. KPS: 100'}].each_with_index do |encounter_note_hash, i|
      note = FactoryGirl.create(:note, person: @person, note_text: encounter_note_hash['Note Text'])
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  @abstractor_namespace_encoutner_note.id)
    end
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    expect(page).to have_content('Karnofsky performance status')

    within(".has_karnofsky_performance_status") do
      expect(find_field('100% - Normal; no complaints; no evidence of disease.', visible: false)['checked']).to be_falsy
    end

    within(".has_karnofsky_performance_status_date") do
      expect(find_field('2014-06-26', visible: false)['checked']).to be_falsy
    end

    expect(find('.has_karnofsky_performance_status')).to have_content('Edit')

    expect(find('.has_karnofsky_performance_status_date')).to have_content('Edit')

    expect(find('.has_karnofsky_performance_status')).to have_content('CLEAR')

    expect(find('.has_karnofsky_performance_status_date')).to have_content('CLEAR')

    expect(find('.has_karnofsky_performance_status_date .custom_explanation .explanation_text')).to have_content('A bit of custom logic')
  end

  scenario 'Viewing an abstraction with an unknown suggestion', js: true, focus: false do
    [{'Note Text' => 'Hello, I have no idea what is your KPS.'}].each_with_index do |encounter_note_hash, i|
      note = FactoryGirl.create(:note, person: @person, note_text: encounter_note_hash['Note Text'])
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  @abstractor_namespace_encoutner_note.id)
    end
    @note = Note.last

    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(page).to have_content('Karnofsky performance status')

    expect(page.has_css?('.has_karnofsky_performance_status .abstractor_suggestion_status_selection')).to be_falsy
    expect(page.has_css?('.has_karnofsky_performance_status_date .abstractor_suggestion_status_selection', visible: false)).to be_truthy
    expect(page).to have_unchecked_field('2014-06-26', visible: false)
    expect(find('.has_karnofsky_performance_status')).to have_content('Edit')
    expect(find('.has_karnofsky_performance_status_date')).to have_content('Edit')
    expect(find('.has_karnofsky_performance_status')).to have_content('CLEAR')
    expect(find('.has_karnofsky_performance_status_date')).to have_content('CLEAR')
    expect(find('.has_karnofsky_performance_status_date .custom_explanation .explanation_text')).to have_content('A bit of custom logic')
  end

  scenario 'Accepting a suggestion for an abstraction', js: true, focus: false do
    [{'Note Text' => 'Looking good. KPS: 100'}].each_with_index do |encounter_note_hash, i|
      note = FactoryGirl.create(:note, person: @person, note_text: encounter_note_hash['Note Text'])
      note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
      note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  @abstractor_namespace_encoutner_note.id)
    end

    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      check('100', allow_label_click: true)
    end

    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('100', visible: false)
    end

    expect(find('.has_karnofsky_performance_status .abstractor_suggestion_status', match: :first)).to have_content('100% - Normal; no complaints; no evidence of disease.')
    expect(find('.has_karnofsky_performance_status')).to have_content('Edit')
    expect(find('.has_karnofsky_performance_status')).to have_content('CLEAR')
  end

  scenario 'Accepting a suggestion for an abstraction having multiple suggestions', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Looking good. KPS: 90.  I recommended an appointment in 6 months.  I hope his kps will be 100 then.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      check('100', allow_label_click: true)
    end
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('100', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('90', visible: false)
    end

    expect(find('.has_karnofsky_performance_status')).to have_content('Edit')
    expect(find('.has_karnofsky_performance_status')).to have_content('CLEAR')

    within('.has_karnofsky_performance_status') do
      check('90', allow_label_click: true)
    end
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('100', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('90', visible: false)
    end
  end

  scenario 'Editing an abstraction with an actual suggestion', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Looking good. KPS: 100'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      click_link('Edit')
    end
    sleep(1)

    karnofsky_performance_status = '60% - Requires occasional assistance, but is able to care for most of his personal needs.'
    find('div.select-wrapper input').click #open the dropdown
    sleep(1)
    find('div.select-wrapper li', text: karnofsky_performance_status).click #select the option wanted

    click_button('Save')
      visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('60', visible: false)
    end
  end

  scenario 'Editing an abstraction with an unknown suggestion', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, I have no idea what is your KPS.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_karnofsky_performance_status .abstractor_suggestions')).to have_content('unknown')

    within('.has_karnofsky_performance_status') do
      click_link('Edit')
    end
    sleep(1)

    karnofsky_performance_status = '60% - Requires occasional assistance, but is able to care for most of his personal needs.'

    find('div.select-wrapper input').click #open the dropdown
    sleep(1)
    find('div.select-wrapper li', text: karnofsky_performance_status).click #select the option wanted

    click_button('Save')
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('60', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      click_link('Edit')
    end

    sleep(1)

    click_link('Cancel')
    sleep(1)

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('60', visible: false)
    end
  end

  scenario "Editing an abstraction for 'list' abstraction and saving with a blank value", js: true, focus: false do
    abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
    note = FactoryGirl.create(:note, person: @person, note_text: 'Looking good. KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  abstractor_namespace_encoutner_note.id)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_karnofsky_performance_status') do
      click_link('Edit')
    end

    sleep(1)
    expect(page).to_not have_css(".has_karnofsky_performance_status div.invalid")

    click_button('Save')

    sleep(1)

    expect(page).to have_css(".has_karnofsky_performance_status div.invalid")
    expect(all(".has_karnofsky_performance_status .helper-text")[0]['data-error']).to eq(Abstractor::Enum::ABSTRACTOR_ABSTRACTION_VALIDATION_ERROR)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('100', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('not applicable', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('unknown', visible: false)
    end
  end

  scenario "Editing an abstraction for 'number' abstraction and saving with a blank value", js: true, focus: false do
    abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
    note = FactoryGirl.create(:note, person: @person, note_text: 'Looking good. KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  abstractor_namespace_encoutner_note.id)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_numeric_schema') do
      click_link('Edit')
    end

    sleep(1)
    expect(page).to_not have_css(".has_numeric_schema input.invalid")

    click_button('Save')

    sleep(1)

    expect(page).to have_css(".has_numeric_schema input.invalid")
    expect(all(".has_numeric_schema .helper-text")[0]['data-error']).to eq(Abstractor::Enum::ABSTRACTOR_ABSTRACTION_VALIDATION_ERROR)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    within('.has_numeric_schema') do
      expect(page).to have_unchecked_field('not applicable', visible: false)
    end

    within('.has_numeric_schema') do
      expect(page).to have_unchecked_field('unknown', visible: false)
    end
  end

  scenario "Editing an abstraction for 'date' abstraction and saving with a blank value", js: true, focus: false do
    abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
    note = FactoryGirl.create(:note, person: @person, note_text: 'Looking good. KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  abstractor_namespace_encoutner_note.id)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_date_schema') do
      click_link('Edit')
    end

    sleep(1)
    expect(page).to_not have_css(".has_date_schema input.invalid")

    click_button('Save')

    sleep(1)

    expect(page).to have_css(".has_date_schema input.invalid")
    expect(all(".has_date_schema .helper-text")[0]['data-error']).to eq(Abstractor::Enum::ABSTRACTOR_ABSTRACTION_VALIDATION_ERROR)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    sleep(1)
    within('.has_date_schema') do
      expect(page).to have_unchecked_field('not applicable', visible: false)
    end

    within('.has_date_schema') do
      expect(page).to have_unchecked_field('unknown', visible: false)
    end
  end

  scenario "Editing an abstraction for 'text' abstraction and saving with a blank value", js: true, focus: false do
    abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
    note = FactoryGirl.create(:note, person: @person, note_text: 'Looking good. KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  abstractor_namespace_encoutner_note.id)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_text_schema') do
      click_link('Edit')
    end

    sleep(1)
    expect(page).to_not have_css(".has_text_schema textarea.invalid")

    click_button('Save')

    sleep(1)

    expect(page).to have_css(".has_text_schema textarea.invalid")
    expect(all(".has_text_schema .helper-text")[0]['data-error']).to eq(Abstractor::Enum::ABSTRACTOR_ABSTRACTION_VALIDATION_ERROR)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    sleep(1)
    within('.has_text_schema') do
      expect(page).to have_unchecked_field('not applicable', visible: false)
    end

    within('.has_text_schema') do
      expect(page).to have_unchecked_field('unknown', visible: false)
    end
  end

  scenario "Editing an abstraction for 'string' abstraction and saving with a blank value", js: true, focus: false do
    abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
    note = FactoryGirl.create(:note, person: @person, note_text: 'Looking good. KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  abstractor_namespace_encoutner_note.id)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page

    within('.has_string_schema') do
      click_link('Edit')
    end

    sleep(1)
    expect(page).to_not have_css(".has_string_schema input.invalid")

    click_button('Save')

    sleep(1)

    expect(page).to have_css(".has_string_schema input.invalid")
    expect(all(".has_string_schema .helper-text")[0]['data-error']).to eq(Abstractor::Enum::ABSTRACTOR_ABSTRACTION_VALIDATION_ERROR)

    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    sleep(1)
    within('.has_string_schema') do
      expect(page).to have_unchecked_field('not applicable', visible: false)
    end

    within('.has_string_schema') do
      expect(page).to have_unchecked_field('unknown', visible: false)
    end
  end

  scenario 'Viewing source for suggestion with source and match value', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'The patient is looking good.  KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    find(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
  end

  scenario 'Viewing source for multiple suggestion with source and match value', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'The patient is looking good.  KPS: 100.  But the KPS could also be 60.  Also the numeric schema is 55.')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    all(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
    not_match_highlighted_text('.abstractor_source_tab_content', 'But the KPS could also be 60.')
    all(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img')[1].click
    not_match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'But the KPS could also be 60.')
  end

  scenario 'Viewing source for suggestion with source and match value after accepting a suggestion', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'The patient is looking good.  KPS: 100')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    find(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')

    within('.has_karnofsky_performance_status') do
      check('100', allow_label_click: true)
    end
    sleep(1)
    not_match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
  end

  scenario 'Viewing source for multiple suggestion with source and match value after accepting a suggestion for another abstraction', js: true, focus: false do
    note = FactoryGirl.create(:note, person: @person, note_text: 'The patient is looking good.  KPS: 100.  But the KPS could also be 60.  Also the numeric schema is 85.')
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    all(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
    not_match_highlighted_text('.abstractor_source_tab_content', 'But the KPS could also be 60.')

    within('.has_numeric_schema') do
      check('85', allow_label_click: true)
    end
    sleep(1)
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
  end

  scenario 'Viewing source for suggestion with source containing characters needing to be escaped and match value', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'The patient is looking good & fit. Much > than I would have thought.  KPS: 100'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    find(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good & fit. Much > than I would have thought. KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
  end

  scenario 'Viewing source for suggestion with a source and no match value', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, your KPS is something. Have a great day!'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(page).to_not have_css('.has_karnofsky_performance_status_date span.abstractor_abstraction_source_tooltip_img')
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('Hello, your KPS is something. Have a great day!')
  end

  scenario 'Viewing source for suggestion with source containing characters needing to be escaped and no match value', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'The patient is looking good & fit. Much > than I would have thought. The KPS is something. Have a great day!'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(page).to_not have_css('.has_karnofsky_performance_status_date span.abstractor_abstraction_source_tooltip_img')
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good & fit. Much > than I would have thought. The KPS is something. Have a great day!')
  end

  scenario 'Viewing source for suggestion with source and multiple match values', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, your KPS is 100%. Have a great day! Yes, KPS is 100%! And then I elaborated.  KPS: 100.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    find(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').click
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('Hello, your KPS is 100%. Have a great day! Yes, KPS is 100%! And then I elaborated. KPS: 100.')
    match_highlighted_text('.abstractor_source_tab_content', 'Hello, your KPS is 100%.')
    match_highlighted_text('.abstractor_source_tab_content', 'Yes, KPS is 100%!')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
  end

  scenario 'User clearing an abstraction', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, your KPS is 100%.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    within('.has_karnofsky_performance_status') do
      check('100', allow_label_click: true)
    end
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('100', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      click_link('Clear')
    end

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('100', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      click_link('Edit')
    end
    sleep(1)

    karnofsky_performance_status = '60% - Requires occasional assistance, but is able to care for most of his personal needs.'
    find('div.select-wrapper input').click #open the dropdown
    find('div.select-wrapper li', text: karnofsky_performance_status).click #select the option wanted

    click_button('Save')
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('60', visible: false)
    end

    within('.has_karnofsky_performance_status') do
      click_link('Clear')
    end
    sleep(1)
    expect(find('.has_karnofsky_performance_status .abstractor_suggestion', match: :first)).to have_content('100%')
    all('.has_karnofsky_performance_status .abstractor_suggestion').each do |fragment|
      expect(fragment).not_to have_content('60%')
    end
  end

  scenario 'User creating abstraction when matching suggestion exists', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, you look good to me. KPS: 100'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)

    within('.has_karnofsky_performance_status') do
      expect(page).to have_unchecked_field('100', visible: false)
    end
    within('.has_karnofsky_performance_status') do
      click_link('Edit')
    end
    sleep(1)

    karnofsky_performance_status = '100% - Normal; no complaints; no evidence of disease.'
    find('div.select-wrapper input').click #open the dropdown
    find('div.select-wrapper li', text: karnofsky_performance_status).click #select the option wanted

    click_button('Save')
    sleep(1)
    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('100', visible: false)
    end
  end

  scenario 'User setting the value of an abstraction schema with a date object type', js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, I have no idea what is your KPS.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)

    within('.has_karnofsky_performance_status_date') do
      click_link('Edit')
    end
    sleep(1)

    within('.has_karnofsky_performance_status_date') do
      fill_in('abstractor_abstractor_abstraction_value', with: '2014-06-03')
    end
    click_button('Save')
    sleep(1)
    within('.has_karnofsky_performance_status_date') do
      expect(page).to have_checked_field('2014-06-03', visible: false)
    end
  end

  scenario "User setting all the values to 'not applicable' for an abstractable entity", js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, I have no idea what is your KPS.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(find('.has_karnofsky_performance_status ')).to have_content('unknown')
    within('.has_karnofsky_performance_status_date') do
      expect(page).to have_unchecked_field('2014-06-26', visible: false)
    end

    accept_confirm do
      click_link('Not applicable all')
    end
    sleep(1)

    within('.has_karnofsky_performance_status') do
      expect(page).to have_checked_field('not applicable', visible: false)
    end

    within('.has_karnofsky_performance_status_date') do
      expect(page).to have_checked_field('not applicable', visible: false)
    end
  end

  scenario "User setting all the values to 'unknown' for an abstractable entity", js: true, focus: false do
    create_encounter_notes([{'Note Text' => 'Hello, I have no idea what is your KPS.'}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    expect(find('.has_karnofsky_performance_status ')).to have_content('unknown')
    within('.has_karnofsky_performance_status_date') do
      expect(page).to have_unchecked_field('2014-06-26', visible: false)
    end

    accept_confirm do
      click_link('Unknown all')
    end
    sleep(1)

    expect(find('.has_karnofsky_performance_status')).to have_content('unknown')
    expect(find('.has_karnofsky_performance_status_date')).to have_content('unknown')
  end

  scenario "Viewing source for suggestion with source and match value with the match value requiring scroll to.", js: true, focus: false do
    note_text = "Little my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\nLittle my says hi!\n The patient is looking good.  KPS: 100"
    create_encounter_notes([{'Note Text' => note_text}])
    @note = Note.last
    visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    sleep(1)
    find(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(find('.abstractor_source_tab label')).to have_content('Note text')
    expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
    match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
  end

  describe 'Navigating to a page with the back button' do
    before(:each) do
      @procedure_occurrence = FactoryGirl.create(:procedure_occurrence, person_id: @person.id)
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient is looking good.  KPS: 100')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  @abstractor_namespace_encoutner_note.id)
      @other_note = FactoryGirl.create(:note, person: @person, note_text: 'Another note.', note_title: 'Another note title')

      FactoryGirl.create(:fact_relationship, domain_concept_id_1: @concept_domain_procedure.concept_id, fact_id_1: @procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: @concept_domain_note.concept_id, fact_id_2: @note.note_id, relationship_concept_id:@relationship_proc_context_of.relationship_concept_id)
      FactoryGirl.create(:fact_relationship, domain_concept_id_1: @concept_domain_note.concept_id, fact_id_1: @note.note_id, domain_concept_id_2: @concept_domain_procedure.concept_id, fact_id_2: @procedure_occurrence.procedure_occurrence_id, relationship_concept_id: @relationship_has_procedure_context.relationship_concept_id)

      FactoryGirl.create(:fact_relationship, domain_concept_id_1: @concept_domain_procedure.concept_id, fact_id_1: @procedure_occurrence.procedure_occurrence_id, domain_concept_id_2: @concept_domain_note.concept_id, fact_id_2: @other_note.note_id, relationship_concept_id:@relationship_proc_context_of.relationship_concept_id)
      FactoryGirl.create(:fact_relationship, domain_concept_id_1: @concept_domain_note.concept_id, fact_id_1: @other_note.note_id, domain_concept_id_2: @concept_domain_procedure.concept_id, fact_id_2: @procedure_occurrence.procedure_occurrence_id, relationship_concept_id: @relationship_has_procedure_context.relationship_concept_id)
    end

    scenario 'Viewing modals.', js: true, focus: false do
      visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
      logs_in('mjg994', 'secret')
      all('#procedure_occurrences .note')[0].find('.note_view').click
      sleep(1)
      expect(all('#procedure_occurrences .note')[0].find('.note_text')).to have_content('Another note.')
      visit(root_path())
      sleep(1)
      click_the_back_button
      sleep(1)
      all('#procedure_occurrences .note')[0].find('.note_view').click
      sleep(1)
      expect(all('#procedure_occurrences .note')[0].find('.note_text')).to have_content('Another note.')
    end

    scenario 'Highlighting text when there is currently highlighted text', js: true, focus: false do
      pending 'This should pass: It appears that Capybara does not really simulate clicking the back button.'
      visit(edit_note_path(@note.note_id, previous_note_id: @note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id))
      logs_in('mjg994', 'secret')
      scroll_to_bottom_of_the_page
      sleep(1)
      find(:css, '.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').click
      within('.abstractor_source_tab') do
        expect(page).to have_css("[style*='background-color: yellow;']")
      end
      expect(find('.abstractor_source_tab label')).to have_content('Note text')
      expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
      match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
      sleep(1)
      visit(root_path())
      sleep(1)
      click_the_back_button
      sleep(1)
      within('.abstractor_source_tab') do
        expect(page).to have_css("[style*='background-color: yellow;']")
      end
      expect(find('.abstractor_source_tab label')).to have_content('Note text')
      expect(find('.abstractor_source_tab_content')).to have_content('The patient is looking good. KPS: 100')
      match_highlighted_text('.abstractor_source_tab_content', 'KPS: 100')
    end
  end
end

def create_encounter_notes(encountr_notes)
  abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
  encountr_notes.each_with_index do |encounter_note_hash, i|
    note = FactoryGirl.create(:note, person: @person, note_text: encounter_note_hash['Note Text'])
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  abstractor_namespace_encoutner_note.id)
  end
end
