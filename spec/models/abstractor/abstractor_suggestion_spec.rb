require 'rails_helper'
describe  Abstractor::AbstractorSuggestion do
  before(:each) do
    Abstractor::Setup.system
  end

  it "can detect a suggestion from a suggested value", focus: false do
    abstractor_object_type = Abstractor::AbstractorObjectType.first
    abstractor_abstraction_schema = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property')
    abstractor_rule_type = Abstractor::AbstractorRuleType.first
    abstractor_abstraction_source_type = Abstractor::AbstractorAbstractionSourceType.first
    abstractor_abstraction_schema.abstractor_subjects << FactoryGirl.build(:abstractor_subject, subject_type: NoteStableIdentifier.to_s)
    abstractor_abstraction_source = FactoryGirl.create(:abstractor_abstraction_source, abstractor_subject: abstractor_abstraction_schema.abstractor_subjects.first, abstractor_rule_type: abstractor_rule_type, abstractor_abstraction_source_type: abstractor_abstraction_source_type, section_name: 'moomin')
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @note = FactoryGirl.create(:note, person: @person, note_text: nil)
    @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
    abstractor_abstraction = FactoryGirl.create(:abstractor_abstraction, abstractor_subject: abstractor_abstraction_schema.abstractor_subjects.first, about: @note_stable_identifier , unknown: true)
    abstractor_suggestion_bar = FactoryGirl.create(:abstractor_suggestion, abstractor_abstraction: abstractor_abstraction, accepted: true, suggested_value: 'bar')
    abstractor_suggestion_boo = FactoryGirl.create(:abstractor_suggestion, abstractor_abstraction: abstractor_abstraction, accepted: true, suggested_value: 'boo')
    abstractor_suggestion_source_bar = FactoryGirl.create(:abstractor_suggestion_source, abstractor_suggestion: abstractor_suggestion_bar, abstractor_abstraction_source: abstractor_abstraction_source, match_value: 'bar', sentence_match_value: 'bar', source_id: 1, source_type: 'Foo', source_method: 'boo', section_name: 'moomin')
    suggestion_source_bar_like = FactoryGirl.create(:abstractor_suggestion_source, abstractor_suggestion: abstractor_suggestion_bar, abstractor_abstraction_source: abstractor_abstraction_source, match_value: 'bar-like', source_id: 1, source_type: 'Foo', source_method: 'bing', section_name: 'moomin')

    expect(abstractor_suggestion_bar.detect_abstractor_suggestion_source(abstractor_abstraction_source, 'bar', 1, 'Foo', 'boo', 'moomin')).to eq(abstractor_suggestion_source_bar)
  end
end
