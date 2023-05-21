require 'rails_helper'
describe NoteStableIdentifier do
  before(:each) do
    Abstractor::Setup.system
    list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
    v_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
    source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
    @favorite_baseball_team_abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_favorite_baseball_team', display_name: 'Favorite baseball team', abstractor_object_type: list_object_type, preferred_name: 'Favorite baseball team')
    @favorite_baseball_team_abstractor_subject= Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @favorite_baseball_team_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2)
    @abstractor_object_value_white_sox = FactoryGirl.create(:abstractor_object_value, value: 'White Sox')
    Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_baseball_team_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_white_sox)
    @abstractor_object_value_cubs = FactoryGirl.create(:abstractor_object_value,value: 'Cubs')
    Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_baseball_team_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_cubs)
    @abstractor_object_value_twins = FactoryGirl.create(:abstractor_object_value,value: 'Twins')
    Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_baseball_team_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_twins)
    Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @favorite_baseball_team_abstractor_subject, from_method: 'note_text', abstractor_rule_type: v_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion)
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  describe "querying by abstractor suggestion type" do
    it "can report what has an 'unknown' suggestion type", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to eq([@note_stable_identifier])
    end

    it "reports empty what has a 'unknown' suggestion type when there is a 'suggested' suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload
      pending "Expected to fail: Need to figure out why we thought the following expectation should be empty."
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to be_empty
    end

    it "reports not empty what has a 'unknown' suggestion type when there is a deleted 'suggested' suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload
      @abstractor_object_value_white_sox.soft_delete!
      @note_stable_identifier.reload

      expect(@note_stable_identifier.abstractor_abstractions.map { |a| a.abstractor_suggestions.deleted }.size).to eq(1)
      expect(@note_stable_identifier.abstractor_abstractions.map { |a| a.abstractor_suggestions.not_deleted }.size).to eq(1)
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to eq([@note_stable_identifier])
    end

    it "reports empty what has a 'suggested' suggestion type when there is a deleted 'suggested' suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @abstractor_object_value_white_sox.soft_delete!
      @note_stable_identifier.reload
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED)).to be_empty
    end

    it "can report what has a 'suggested' suggestion type", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED)).to eq([@note_stable_identifier])
    end

    it "reports empty what has a 'suggested' suggestion type when there is an 'unknown' suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED)).to be_empty
    end

    it "reports what has an 'unknown' suggestion type, even when a manual suggestion is made", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to eq([@note_stable_identifier])
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@favorite_baseball_team_abstractor_subject)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(2)
      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, @abstractor_object_value_white_sox.value, nil, nil, nil, nil)
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(3)
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to eq([@note_stable_identifier])
    end

    it "reports what has an 'unknown' suggestion type, even when a manual suggestion is made and then its abstraction object value is soft deleted", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to eq([@note_stable_identifier])
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@favorite_baseball_team_abstractor_subject)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(2)
      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, @abstractor_object_value_white_sox.value, nil, nil, nil, nil)
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(3)
      @abstractor_object_value_white_sox.soft_delete!
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN)).to eq([@note_stable_identifier])
    end
  end

  describe "querying by abstractor suggestion type (filtered)" do
    before(:each) do
      list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      unknown_rule = Abstractor::AbstractorRuleType.where(name: 'unknown').first
      @abstractor_abstraction_schema_always_unknown = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_always_unknown', display_name: 'Always unknown', abstractor_object_type: list_object_type, preferred_name: 'Always unknown')
      @abstractor_subject_abstraction_schema_always_unknown = Abstractor::AbstractorSubject.create(:subject_type => NoteStableIdentifier.to_s, :abstractor_abstraction_schema => @abstractor_abstraction_schema_always_unknown)
      source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
      Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_abstraction_schema_always_unknown, from_method: 'note_text', abstractor_abstraction_source_type: source_type_nlp_suggestion, :abstractor_rule_type => unknown_rule)
    end

    it "can report what has an 'unknown' suggestion type", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to eq([@note_stable_identifier])
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to eq([@note_stable_identifier])
    end

    it "reports empty what has an 'unknown' suggestion type when there is a 'suggested' suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      pending "Expected to fail: Need to figure out why we thought the following expectation should be empty."
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to eq([@note_stable_identifier])
    end

    it "reports what has an 'unknown' suggestion type when there is a 'suggested' suggestion thats abstractor object value is soft deleted", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @abstractor_object_value_white_sox.soft_delete!
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to eq([@note_stable_identifier])
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to eq([@note_stable_identifier])
    end

    it "can report what has a 'suggested' suggestion type", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to eq([@note_stable_identifier])
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end

    it "reports empty what has a 'suggested' suggestion type when there is an 'unknown' suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end

    it "reports empty what has a 'suggested' suggestion type when the abstractor object value is soft deleted", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'I love the white sox.  Minnie Minoso should be in the hall of fame.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @abstractor_object_value_white_sox.soft_delete!
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end

    it "reports what has an 'unknown' suggestion type, even when a manual suggestion is made", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@favorite_baseball_team_abstractor_subject)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(2)
      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, @abstractor_object_value_white_sox.value, nil, nil, nil, nil)
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(3)
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end

    it "reports what has an 'unknown' suggestion type, even when a manual suggestion is made and its abstractor object value is soft deleted", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@favorite_baseball_team_abstractor_subject)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(2)

      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, @abstractor_object_value_white_sox.value, nil, nil, nil, nil)
      @abstractor_object_value_white_sox.soft_delete!
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(3)
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_baseball_team_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end
  end

  describe "querying by abstractor suggestion (namespaced)" do
    before(:each) do
      Abstractor::Setup.system
      list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      v_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
      source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
      @favorite_philosopher_abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_favorite_philosopher', display_name: 'Favorite philosopher', abstractor_object_type: list_object_type, preferred_name: 'Favorite philosopher')
      @favorite_philosopher_abstractor_subject = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
      @abstractor_object_value_rorty = FactoryGirl.create(:abstractor_object_value, value: 'Rorty')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_rorty)
      @abstractor_object_value_wittgenstein = FactoryGirl.create(:abstractor_object_value,value: 'Wittgenstein')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_wittgenstein)
      @abstractor_object_value_dennet = FactoryGirl.create(:abstractor_object_value,value: 'Dennet')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_dennet)
      Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @favorite_philosopher_abstractor_subject, from_method: 'note_text', abstractor_rule_type: v_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion)
    end

    it "can report what has an 'unknown' suggestion type (namespaced)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, namespace_type: 'Discerner::Search', namespace_id: 1)).to eq([@note_stable_identifier])
    end

    it "reports empty what has a 'unknown' suggestion type when there is a suggested suggestion (namespaced)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Richard Rorty was facile. But very entertaining.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      pending "Expected to fail: Need to figure out why we thought the following expectation should be empty."
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, namespace_type: 'Discerner::Search', namespace_id: 1)).to be_empty
    end

    it "can report what has a 'suggested' suggestion type (namespaced)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Richard Rorty was facile. But very entertaining.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1)).to eq([@note_stable_identifier])
    end

    it "reports empty what has a 'suggested' suggestion type when there is an 'unknown' suggestion (namespaced)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1)).to be_empty
    end

    it "reports what has an 'unknown' suggestion type, even when a manual suggestion is made", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to be_empty
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@favorite_philosopher_abstractor_subject)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(2)
      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, @abstractor_object_value_rorty.value, nil, nil, nil, nil)
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(3)
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [])).to be_empty
    end
  end

  describe "querying by abstractor suggestion (namespaced) (filtered)" do
    before(:each) do
      Abstractor::Setup.system
      list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      v_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
      unknown_rule = Abstractor::AbstractorRuleType.where(name: 'unknown').first
      source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
      @favorite_philosopher_abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_favorite_philosopher', display_name: 'Favorite philosopher', abstractor_object_type: list_object_type, preferred_name: 'Favorite philosopher')
      @favorite_philosopher_abstractor_subject = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
      @abstractor_object_value_rorty = FactoryGirl.create(:abstractor_object_value, value: 'Rorty')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_rorty)
      @abstractor_object_value_wittgenstein = FactoryGirl.create(:abstractor_object_value, value: 'Wittgenstein')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_wittgenstein)
      @abstractor_object_value_dennet = FactoryGirl.create(:abstractor_object_value, value: 'Dennet')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_dennet)
      Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @favorite_philosopher_abstractor_subject, from_method: 'note_text', abstractor_rule_type: v_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion)
      @abstractor_abstraction_schema_always_unknown = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_always_unknown', display_name: 'Always unknown', abstractor_object_type: list_object_type, preferred_name: 'Always unknown')
      @abstractor_subject_abstraction_schema_always_unknown = Abstractor::AbstractorSubject.create(:subject_type => NoteStableIdentifier.to_s, :abstractor_abstraction_schema => @abstractor_abstraction_schema_always_unknown, namespace_type: 'Discerner::Search', namespace_id: 1)
      source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
      Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_abstraction_schema_always_unknown, from_method: 'note_text', abstractor_abstraction_source_type: source_type_nlp_suggestion, :abstractor_rule_type => unknown_rule)
    end

    it 'can report what has an unknown suggestion type (namespaced)', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to eq([@note_stable_identifier])
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to eq([@note_stable_identifier])
    end

    it 'reports empty what has a unknown suggestion type when there is a suggested suggestion (namespaced)', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Richard Rorty was facile. But very entertaining.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      pending "Expected to fail: Need to figure out why we thought the following expectation should be empty."
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_UNKNOWN, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to eq([article])
    end

    it 'can report what has a suggested suggestion type (namespaced)', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Richard Rorty was facile. But very entertaining.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to eq([@note_stable_identifier])
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end

    it 'reports empty what has a suggested suggestion type when there is an unknown suggestion (namespaced)', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end

    it "reports what has an 'unknown' suggestion type, even when a manual suggestion is made", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
      @note_stable_identifier.reload

      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to be_empty
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@favorite_philosopher_abstractor_subject)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(2)
      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, @abstractor_object_value_rorty.value, nil, nil, nil, nil)
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(3)
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@favorite_philosopher_abstractor_abstraction_schema])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
      expect(NoteStableIdentifier.by_abstractor_suggestion_type(Abstractor::Enum::ABSTRACTION_SUGGESTION_TYPE_SUGGESTED, namespace_type: 'Discerner::Search', namespace_id: 1, abstractor_abstraction_schemas: [@abstractor_abstraction_schema_always_unknown])).to be_empty
    end
  end

  describe "querying by workflow status" do
    before(:each) do
      Abstractor::Setup.system
      list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      v_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
      source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
      @favorite_philosopher_abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_favorite_philosopher', display_name: 'Favorite philosopher', abstractor_object_type: list_object_type, preferred_name: 'Favorite philosopher')
      abstractor_subject = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
      @abstractor_object_value_rorty = FactoryGirl.create(:abstractor_object_value, value: 'Rorty')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_rorty)
      @abstractor_object_value_wittgenstein = FactoryGirl.create(:abstractor_object_value, value: 'Wittgenstein')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_wittgenstein)
      @abstractor_object_value_dennet = FactoryGirl.create(:abstractor_object_value, value: 'Dennet')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @favorite_philosopher_abstractor_abstraction_schema, abstractor_object_value: @abstractor_object_value_dennet)
      Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject, from_method: 'note_text', abstractor_rule_type: v_rule, abstractor_abstraction_source_type: source_type_nlp_suggestion)
    end


    it "can report against all workflow statuses", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_2 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
      @note_stable_identifier_2.abstract

      @note_stable_identifier_2.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.save!
      end

      @note_3 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_3 = FactoryGirl.create(:note_stable_identifier, note: @note_3)
      @note_stable_identifier_3.abstract

      @note_stable_identifier_3.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.save!
      end

      expect(NoteStableIdentifier.by_abstraction_workflow_status('All')).to eq([@note_stable_identifier, @note_stable_identifier_2,  @note_stable_identifier_3])
      expect(NoteStableIdentifier.by_abstraction_workflow_status(nil)).to eq([@note_stable_identifier, @note_stable_identifier_2,  @note_stable_identifier_3])
    end

    it "can report what has a 'pending' workflow status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_2 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
      @note_stable_identifier_2.abstract

      @note_stable_identifier_2.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.save!
      end

      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)).to eq([@note_stable_identifier])

      @note_3 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_3 = FactoryGirl.create(:note_stable_identifier, note: @note_3)
      @note_stable_identifier_3.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      @note_4 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_4 = FactoryGirl.create(:note_stable_identifier, note: @note_4)
      @note_stable_identifier_4.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

      options = { namespace_type: 'Discerner::Search', namespace_id: 2 }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING, options)).to match_array([@note_stable_identifier, @note_stable_identifier_4])
    end

    it "can report what has a 'submitted' workflow status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.workflow_status_whodunnit = 'little my'
        abstractor_abstraction.save!
      end

      @note_2 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
      @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED)).to eq([@note_stable_identifier])

      @note_3 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_3 = FactoryGirl.create(:note_stable_identifier, note: @note_3)
      @note_stable_identifier_3.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      @note_stable_identifier_3.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.workflow_status_whodunnit = 'moominpapa'
        abstractor_abstraction.save!
      end

      @note_4 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_4 = FactoryGirl.create(:note_stable_identifier, note: @note_4)
      @note_stable_identifier_4.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

      @note_stable_identifier_4.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.workflow_status_whodunnit = 'moominpapa'
        abstractor_abstraction.save!
      end

      options = { workflow_status_whodunnit: 'moominpapa' }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, options)).to match_array([@note_stable_identifier_3, @note_stable_identifier_4])

      options = { workflow_status_whodunnit: 'moominpapa', namespace_type: 'Discerner::Search', namespace_id: 2 }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, options)).to eq([@note_stable_identifier_4])
    end

    it "can report what has a 'discarded' workflow status", focus: false  do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'little my'
        abstractor_abstraction.save!
      end

      @note_2 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
      @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED)).to eq([@note_stable_identifier])

      @note_3 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_3 = FactoryGirl.create(:note_stable_identifier, note: @note_3)
      @note_stable_identifier_3.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      @note_stable_identifier_3.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'moominpapa'
        abstractor_abstraction.save!
      end

      @note_4 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_4 = FactoryGirl.create(:note_stable_identifier, note: @note_4)
      @note_stable_identifier_4.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

      @note_stable_identifier_4.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'moominpapa'
        abstractor_abstraction.save!
      end

      options = { workflow_status_whodunnit: 'moominpapa' }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED, options)).to match_array([@note_stable_identifier_3, @note_stable_identifier_4])

      options = { workflow_status_whodunnit: 'moominpapa', namespace_type: 'Discerner::Search', namespace_id: 2 }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED, options)).to match_array([@note_stable_identifier_4])
    end

    it "can report what has a 'submitted or discarded' workflow status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.workflow_status_whodunnit = 'little my'
        abstractor_abstraction.save!
      end

      @note_2 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
      @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      @note_stable_identifier_2.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'little my'
        abstractor_abstraction.save!
      end

      @note_3 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_3 = FactoryGirl.create(:note_stable_identifier, note: @note_3)
      @note_stable_identifier_3.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED_OR_DISCARDED)).to match_array([@note_stable_identifier, @note_stable_identifier_2])

      @note_4 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_4 = FactoryGirl.create(:note_stable_identifier, note: @note_4)
      @note_stable_identifier_4.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

      @note_stable_identifier_4.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.workflow_status_whodunnit = 'moominpapa'
        abstractor_abstraction.save!
      end

      @note_5 = FactoryGirl.create(:note, person: @person, note_text: 'gobbledy gook')
      @note_stable_identifier_5 = FactoryGirl.create(:note_stable_identifier, note: @note_5)
      @note_stable_identifier_5.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

      @note_stable_identifier_5.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'moominpapa'
        abstractor_abstraction.save!
      end

      options = { workflow_status_whodunnit: 'moominpapa' }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED_OR_DISCARDED, options)).to eq([@note_stable_identifier_4, @note_stable_identifier_5])

      options = { workflow_status_whodunnit: 'moominpapa', namespace_type: 'Discerner::Search', namespace_id: 2 }
      expect(NoteStableIdentifier.by_abstraction_workflow_status(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED_OR_DISCARDED, options)).to eq([@note_stable_identifier_4])
    end
  end
end