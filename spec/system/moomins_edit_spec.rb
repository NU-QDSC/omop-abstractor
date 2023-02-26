require 'rails_helper'
RSpec.feature 'Editing moomin: User should be able to edit moomin information', type: :system do
  before(:each) do
    Abstractor::Setup.system
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

  scenario 'Editing a moomin with no sections setup', js: true, focus: false do
    moomin_abstaction_schemas_with_no_sections
    note_text = "I like little my the best!\nfavorite moomin:\nThe groke is the bomb!"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(page).to have_unchecked_field('Little My', visible: false)
    expect(page).to have_unchecked_field('The Groke', visible: false)
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab_content')[0]).to have_content("I like little my the best!\nfavorite moomin:\nThe groke is the bomb!")
    match_highlighted_text('.abstractor_source_tab_content', 'little my')
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[1].click
    match_highlighted_text('.abstractor_source_tab_content', 'The groke')
    sleep(1)
  end

  scenario 'Editing a moomin with a section setup and a section name variant is mentioned', js: true, focus: false do
    moomin_abstaction_schemas_with_sections
    note_text = "I like little my the best!\nbeloved moomin:\nThe groke is the bomb!"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_favorite_moomin')).to_not have_content('Little My')
    expect(page).to have_unchecked_field('The Groke', visible: false)
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab_content')[0]).to have_content("The groke is the bomb!")
    match_highlighted_text('.abstractor_source_tab_content', 'The groke')
  end

  scenario 'Editing a moomin with a section setup and more than one section name variant is mentioned', js: true, focus: false do
    moomin_abstaction_schemas_with_sections
    note_text = "I like little my the best!\nfavorite moomin:\nThe groke is the bomb!\nbeloved moomin:\nMoomintroll is the bomb!"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_favorite_moomin')).to_not have_content('Little My')
    expect(page).to have_unchecked_field('The Groke', visible: false)
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab_content')[0]).to have_content("The groke is the bomb!")
    match_highlighted_text('.abstractor_source_tab_content', 'The groke')
  end

  scenario 'Editing a moomin with a section setup and return note on empty section is set to true', js: true, focus: false do
    moomin_abstaction_schemas_with_sections
    moomin_abstaction_schemas_have_return_note_on_empty_section('true')
    note_text = "I like little my the best!\nWorse moomin:\nThe groke is terrible!"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_favorite_moomin')).to have_content('Little My')
    expect(find('.has_favorite_moomin')).to have_content('The Groke')
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab_content')[0]).to have_content("I like little my the best!\nWorse moomin:\nThe groke is terrible!")
    match_highlighted_text('.abstractor_source_tab_content', 'little my')
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[1].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    match_highlighted_text('.abstractor_source_tab_content', 'The groke')
  end

  scenario 'Editing a moomin with a section setup and return note on empty section is set to false', js: true, focus: false do
    moomin_abstaction_schemas_with_sections
    moomin_abstaction_schemas_have_return_note_on_empty_section('false')
    note_text = "I like little my the best!\nWorse moomin:\nThe groke is terrible!"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_favorite_moomin')).to_not have_content('Little My')
    expect(find('.has_favorite_moomin')).to_not have_content('The Groke')
    expect(find('.has_favorite_moomin')).to_not have_content('Unknown')
    expect(all('.has_karnofsky_performance_status span.abstractor_abstraction_source_tooltip_img').size).to eq(0)
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab_content')[0]).to have_content("")
  end

  scenario 'Editing a moomin with a custom section setup', js: true, focus: false do
    moomin_abstaction_schemas_with_custom_section
    note_text = "I like little my the best!\nCool moomin: The groke is the bomb!"
    note = FactoryGirl.create(:note, person: @person, note_text: note_text, note_date: Date.parse('1/1/2014'))
    note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
    note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
    visit(edit_note_path(note.note_id, previous_note_id: note.note_id, index: 0, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id))
    logs_in('mjg994', 'secret')
    scroll_to_bottom_of_the_page
    expect(find('.has_favorite_moomin')).to_not have_content('Little My')
    expect(find('.has_favorite_moomin')).to have_content('The Groke')
    all('.has_favorite_moomin span.abstractor_abstraction_source_tooltip_img')[0].click
    within('.abstractor_source_tab') do
      expect(page).to have_css("[style*='background-color: yellow;']")
    end
    expect(all('.abstractor_source_tab label')[0]).to have_content('Note text')
    expect(all('.abstractor_source_tab_content')[0]).to have_content("The groke is the bomb!")
    match_highlighted_text('.abstractor_source_tab_content', 'The groke')
  end
end

def setup_moomin_abstraction_schemas
  @abstractor_namespace_moomin_note = Abstractor::AbstractorNamespace.where(name: 'Moomin Note', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create
  list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
  abstractor_abstraction_schema_moomin = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_favorite_moomin', display_name: 'Has favorite moomin', abstractor_object_type_id: list_object_type.id, preferred_name: 'Has favorite moomin').first_or_create

  ['Moomintroll', 'Little My', 'The Groke'].each do |moomin|
    abstractor_object_value = Abstractor::AbstractorObjectValue.create(value: moomin, vocabulary_code: moomin)
    Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: abstractor_abstraction_schema_moomin, abstractor_object_value: abstractor_object_value)
  end

  @abstractor_subject_moomin = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: abstractor_abstraction_schema_moomin, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_moomin_note.id)
end

def moomin_abstaction_schemas_with_no_sections
  setup_moomin_abstraction_schemas
  value_rule_type = Abstractor::AbstractorRuleType.where(name: 'value').first
  source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
  Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: value_rule_type, abstractor_abstraction_source_type: source_type_nlp_suggestion)
end

def moomin_abstaction_schemas_with_sections
  setup_moomin_abstraction_schemas
  value_rule_type = Abstractor::AbstractorRuleType.where(name: 'value').first
  source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
  abstractor_section_type_name_value = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_NAME_VALUE).first
  abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_name_value, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', delimiter: ':')
  abstractor_section_name_varaint = Abstractor::AbstractorSectionNameVariant.create(abstractor_section: abstractor_section, name: 'beloved moomin')
  Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: value_rule_type, abstractor_abstraction_source_type: source_type_nlp_suggestion, section_name: 'favorite moomin')
end

def moomin_abstaction_schemas_with_custom_section
  setup_moomin_abstraction_schemas
  value_rule_type = Abstractor::AbstractorRuleType.where(name: 'value').first
  source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
  abstractor_section_type_custom = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_CUSTOM).first
  abstractor_section = Abstractor::AbstractorSection.create(abstractor_section_type: abstractor_section_type_custom, source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin', custom_regular_expression: "(?<=^|[\r\n])([A-Z][^delimiter]*)delimiter([^\r\n]*(?:[\r\n]+(?![A-Z].*delimiter).*)*)", delimiter: ':')
  abstractor_section_name_varaint = Abstractor::AbstractorSectionNameVariant.create(abstractor_section: abstractor_section, name: 'beloved moomin')
  Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_moomin, from_method: 'note_text', abstractor_rule_type: value_rule_type, abstractor_abstraction_source_type: source_type_nlp_suggestion, section_name: 'favorite moomin')
end

def moomin_abstaction_schemas_have_return_note_on_empty_section(empty_section)
  abstractor_section = Abstractor::AbstractorSection.where(source_type: NoteStableIdentifier.to_s, source_method: 'note_text', name: 'favorite moomin').first
  if empty_section == "true"
    abstractor_section.return_note_on_empty_section = true
  else
    abstractor_section.return_note_on_empty_section = false
  end
  abstractor_section.save!
end