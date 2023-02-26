require 'rails_helper'
describe  Abstractor::AbstractorObjectValue do
  before(:each) do
    Abstractor::Setup.system
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  let(:abstractor_object_type)        { Abstractor::AbstractorObjectType.all.sample }
  let(:abstractor_object_value)       { FactoryGirl.create(:abstractor_object_value, value: 'foo', vocabulary_code: 'foo') }
  let(:abstractor_abstraction_schema) { FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property') }

  it "is valid with valid attributes", focus: false do
    expect(abstractor_object_value).to be_valid
  end

  it "is invalid with invalid attributes", focus: false do
    abstractor_object_value.value = nil
    abstractor_object_value.vocabulary_code = nil

    expect(abstractor_object_value).not_to be_valid
    expect(abstractor_object_value.errors.full_messages).to include("Value can't be blank")
    expect(abstractor_object_value.errors.full_messages).to include("Vocabulary code can't be blank")
  end

  it "can report its object variants", focus: false do
    abstractor_abstraction_schema.abstractor_object_values << FactoryGirl.build(:abstractor_object_value, value: 'foo', vocabulary_code: 'foo')
    FactoryGirl.create(:abstractor_object_value_variant, abstractor_object_value: abstractor_abstraction_schema.abstractor_object_values.first, value: 'boo')
    expect(Set.new(abstractor_abstraction_schema.abstractor_object_values.first.object_variants)).to eq(Set.new(['foo', 'boo']))
  end

  it 'updates timestamp on linked schemas on update', focus: false do
    abstractor_abstraction_schema_object_value            = Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value)
    abstractor_abstraction_schema_timestamp               = abstractor_abstraction_schema.updated_at
    abstractor_abstraction_schema_object_value_timestamp  = abstractor_abstraction_schema_object_value.updated_at

    abstractor_object_value.value = 'boo'
    abstractor_object_value.save!

    expect(abstractor_abstraction_schema.reload.updated_at).to              be > abstractor_abstraction_schema_timestamp
    expect(abstractor_abstraction_schema_object_value.reload.updated_at).to be > abstractor_abstraction_schema_object_value_timestamp
  end

  it 'updates timestamp on linked schemas on destroy', focus: false do
    abstractor_abstraction_schema_object_value            = Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value)
    abstractor_abstraction_schema_timestamp               = abstractor_abstraction_schema.updated_at
    abstractor_abstraction_schema_object_value_timestamp  = abstractor_abstraction_schema_object_value.updated_at

    abstractor_object_value.destroy

    expect(abstractor_abstraction_schema.reload.updated_at).to              be > abstractor_abstraction_schema_timestamp
    expect(abstractor_abstraction_schema_object_value.reload.updated_at).to be > abstractor_abstraction_schema_object_value_timestamp
  end

  describe 'deleting an abstractor object value' do
    before(:each) do
      Abstractor::Setup.system
      OmopAbstractor::SpecSetup.encounter_note
      @abstractor_abstraction_schema_kps = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_karnofsky_performance_status').first
      @abstractor_subject_abstraction_schema_kps = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_kps.id).first
      @abstractor_object_value = @abstractor_abstraction_schema_kps.abstractor_object_values.where(value: '20% - Very sick; hospital admission necessary; active supportive treatment necessary.').first
    end

    it 'cascade soft deletes unaccepted abstractor suggestions upon soft delete of an abstractor object', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.not_deleted.where(suggested_value: @abstractor_object_value.value).first
      expect(abstractor_suggestion).to_not be_nil
      expect(abstractor_suggestion.abstractor_object_value).to eq(@abstractor_object_value)
      @abstractor_object_value.soft_delete!
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.deleted.where(suggested_value: @abstractor_object_value.value).first
      expect(abstractor_suggestion).to_not be_nil
    end

    it 'does not cascade soft deletes accepted abstractor suggestions upon soft delete of an abstractor object', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.not_deleted.where(suggested_value: @abstractor_object_value.value).first
      abstractor_suggestion.accepted = true
      abstractor_suggestion.save!
      expect(abstractor_suggestion).to_not be_nil
      expect(abstractor_suggestion.abstractor_object_value).to eq(@abstractor_object_value)
      @abstractor_object_value.soft_delete!
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.deleted.where(suggested_value: @abstractor_object_value.value).first
      expect(abstractor_suggestion).to be_nil
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.not_deleted.where(suggested_value: @abstractor_object_value.value).first
      expect(abstractor_suggestion).to_not be_nil
    end

    it 'cascade soft deletes unaccepted abstractor suggestions upon soft delete of an abstractor object and create and unknown suggestion if no more suggestions remain', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      pending "Expected to fail: Need to figure out why we thought the following expectation should be true."
      expect(abstractor_abstraction.abstractor_suggestions.not_deleted.select { |abstractor_suggestion| abstractor_suggestion.unknown == true }.empty?).to be_truthy
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.not_deleted.where(suggested_value: @abstractor_object_value.value).first
      expect(abstractor_suggestion).to_not be_nil
      expect(abstractor_suggestion.abstractor_object_value).to eq(@abstractor_object_value)
      @abstractor_object_value.soft_delete!
      abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.deleted.where(suggested_value: @abstractor_object_value.value).first
      expect(abstractor_suggestion).to_not be_nil
      expect(abstractor_abstraction.abstractor_suggestions.not_deleted.select { |abstractor_suggestion| abstractor_suggestion.unknown == true }.empty?).to be_falsy
    end

    it 'cascade soft deletes abstractor object value variants', focus: false do
      expect(@abstractor_object_value.abstractor_object_value_variants.not_deleted.size).to eq(3)
      @abstractor_object_value.soft_delete!
      expect(@abstractor_object_value.abstractor_object_value_variants.not_deleted.size).to eq(0)
      expect(@abstractor_object_value.abstractor_object_value_variants.deleted.size).to eq(3)
    end

    it 'knows if an abstractor object value is used by having an abstractor suggestion', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@abstractor_object_value.used?).to  be_truthy
    end

    it 'knows if an abstractor object value is used by having an abstractor abstraction', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_object_value = @abstractor_abstraction_schema_kps.abstractor_object_values.where(value: '10% - Moribund; fatal processes progressing rapidly.').first
      expect(abstractor_object_value.used?).to be_falsy
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      abstractor_abstraction.value = abstractor_object_value.value
      abstractor_abstraction.save!
      expect(abstractor_object_value.used?).to be_truthy
    end
  end
end