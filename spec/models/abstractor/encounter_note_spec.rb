require 'rails_helper'
describe NoteStableIdentifier do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.encounter_note
    @list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
    @source_type_nlp_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'nlp suggestion').first
    @source_type_custom_suggestion = Abstractor::AbstractorAbstractionSourceType.where(name: 'custom suggestion').first
    @unknown_rule = Abstractor::AbstractorRuleType.where(name: 'unknown').first
    @value_rule = Abstractor::AbstractorRuleType.where(name: 'value').first
    @name_value_rule = Abstractor::AbstractorRuleType.where(name: 'name/value').first
    @abstractor_abstraction_always_unknown = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_always_unknown', display_name: 'Always unknown', abstractor_object_type: @list_object_type, preferred_name: 'Always unknown')
    @abstractor_subject_abstraction_schema_always_unknown = Abstractor::AbstractorSubject.create(:subject_type => 'NoteStableIdentifier', :abstractor_abstraction_schema => @abstractor_abstraction_always_unknown)
    Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_abstraction_schema_always_unknown, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, :abstractor_rule_type => @unknown_rule)

    @abstractor_abstraction_schema_kps = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_karnofsky_performance_status').first
    @abstractor_subject_abstraction_schema_kps = Abstractor::AbstractorSubject.where(abstractor_abstraction_schema_id: @abstractor_abstraction_schema_kps.id).first
    @abstractor_abstraction_schema_kps_date = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_karnofsky_performance_status_date').first
    @abstractor_subject_abstraction_schema_kps_date = Abstractor::AbstractorSubject.where(abstractor_abstraction_schema_id: @abstractor_abstraction_schema_kps_date.id).first
    @abstractor_abstraction_schema_numeric = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_numeric_schema').first
    @abstractor_subject_abstraction_schema_numeric = Abstractor::AbstractorSubject.where(abstractor_abstraction_schema_id: @abstractor_abstraction_schema_numeric.id).first
    @abstractor_abstraction_schema_date = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_date_schema').first
    @abstractor_subject_abstraction_schema_date = Abstractor::AbstractorSubject.where(abstractor_abstraction_schema_id: @abstractor_abstraction_schema_date.id).first
    @abstractor_abstraction_schema_text = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_text_schema').first
    @abstractor_subject_abstraction_schema_text = Abstractor::AbstractorSubject.where(abstractor_abstraction_schema_id: @abstractor_abstraction_schema_text.id).first
    @abstractor_abstraction_schema_string = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_string_schema').first
    @abstractor_subject_abstraction_schema_string = Abstractor::AbstractorSubject.where(abstractor_abstraction_schema_id: @abstractor_abstraction_schema_string.id).first

    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  describe "abstracting" do
    it "can report its abstractor subjects", focus: false do
      abstractor_subjects = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s)
      expect(Set.new(NoteStableIdentifier.abstractor_subjects)).to eq(Set.new(abstractor_subjects))
    end

    it "can report its abstractor subjects by schemas", focus: false do
      expect(Set.new(NoteStableIdentifier.abstractor_subjects(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_kps.id, @abstractor_abstraction_schema_kps_date.id]))).to eq(Set.new([@abstractor_subject_abstraction_schema_kps, @abstractor_subject_abstraction_schema_kps_date]))
    end

    it "can report its abstractor abstraction schemas", focus: false do
      expect(Set.new(NoteStableIdentifier.abstractor_abstraction_schemas)).to eq(Set.new([@abstractor_abstraction_schema_kps, @abstractor_abstraction_always_unknown, @abstractor_abstraction_schema_kps_date, @abstractor_abstraction_schema_numeric, @abstractor_abstraction_schema_date, @abstractor_abstraction_schema_text, @abstractor_abstraction_schema_string]))
    end

    #abstractions
    it "creates a 'has_always_unknown' abstraction for a rule type of 'unknown'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_always_unknown)).to_not be_nil
    end

    it "creates an abstraction with an suggestion of 'unknown' for a rule type of 'unknown'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_always_unknown).abstractor_suggestions.first.unknown).to be_truthy
    end

    it "creates a 'has_karnofsky_performance_status' abstraction'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
    end

    it "creates a 'has_karnofsky_performance_status' abstraction with a workflow status of 'pending", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).workflow_status).to eq(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
    end

    it "does not create another 'has_karnofsky_performance_status' abstraction upon re-abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload.abstract

      expect(@note_stable_identifier.reload.abstractor_abstractions.select { |abstractor_abstraction| abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_karnofsky_performance_status' }.size).to eq(1)
    end

    it "if abstractor_abstraction_schema_ids parameter is set creates abstraction only for selected schemas", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_kps.id, @abstractor_abstraction_schema_kps_date.id])

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date)).to_not be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_always_unknown)).to be_nil

      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date)).to_not be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_always_unknown)).not_to be_nil
    end

    #removing abstractions
    it "can remove abstractions", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
      @note_stable_identifier.remove_abstractions
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to be_nil
    end

    it "will not remove reviewed abstractions (if so instructed)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
      @note_stable_identifier.remove_abstractions
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
    end

    it "can remove abstractions for specified abstraction schemas", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to_not be_nil
      @note_stable_identifier.remove_abstractions(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_kps.id, @abstractor_abstraction_schema_kps_date.id])

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_always_unknown)).not_to be_nil
    end

    #suggestion suggested value
    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a preferred name/predicate (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq('90% - Able to carry on normal activity; minor signs or symptoms of disease.')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a preferred name/predicate (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq('90% - Able to carry on normal activity; minor signs or symptoms of disease.')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a preferred name/predicate (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's Karnofsky performance status is 20.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq("20% - Very sick; hospital admission necessary; active supportive treatment necessary.")
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a predicate variant (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  KPS: 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq('90% - Able to carry on normal activity; minor signs or symptoms of disease.')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a predicate variant (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  KPS: 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq('90% - Able to carry on normal activity; minor signs or symptoms of disease.')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a predicate variant (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  KPS: 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq('90% - Able to carry on normal activity; minor signs or symptoms of disease.')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion suggested value from a predicate variant (using the sentential format) that is equivalent to a object", focus: false do
      abstractor_object_value = FactoryGirl.create(:abstractor_object_value, value: 'kps')
      Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: @abstractor_abstraction_schema_kps, abstractor_object_value: abstractor_object_value)

      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient has a ?kps")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to eq('kps')
    end
    #suggestions
    it "does not create another 'has_karnofsky_performance_status' abstraction suggestion upon re-abstraction (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
    end

    it "does not create another 'has_karnofsky_performance_status' abstraction suggestion upon re-abstraction (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
    end

    it "does not create another 'has_karnofsky_performance_status' abstraction suggestion upon re-abstraction (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
    end

    it "creates multiple 'has_karnofsky_performance_status' abstraction suggestions given multiple different matches (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.  Let me repeat.  KPS: 80')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(Set.new(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(['90% - Able to carry on normal activity; minor signs or symptoms of disease.', '80% - Normal activity with effort; some signs or symptoms of disease.']))
    end

    it "creates multiple 'has_karnofsky_performance_status' abstraction suggestions given multiple different matches (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS90.  Let me repeat.  KPS80')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(Set.new(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(['90% - Able to carry on normal activity; minor signs or symptoms of disease.', '80% - Normal activity with effort; some signs or symptoms of disease.']))
    end

    it "creates multiple 'has_karnofsky_performance_status' abstraction suggestions given multiple different matches (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.  Let me repeat.  The patient's kps is 80.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(Set.new(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(['90% - Able to carry on normal activity; minor signs or symptoms of disease.', '80% - Normal activity with effort; some signs or symptoms of disease.']))
    end

    it "creates one 'has_karnofsky_performance_status' abstraction suggestion given multiple identical matches (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.  Let me repeat.  KPS: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.suggested_value == '90% - Able to carry on normal activity; minor signs or symptoms of disease.'}.size).to eq(1)
    end

    it "creates one 'has_karnofsky_performance_status' abstraction suggestion given multiple identical matches (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS90.  Let me repeat.  KPS90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.suggested_value == '90% - Able to carry on normal activity; minor signs or symptoms of disease.'}.size).to eq(1)
    end

    it "creates one 'has_karnofsky_performance_status' abstraction suggestion given multiple identical matches (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.  Let me repeat.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.suggested_value == '90% - Able to carry on normal activity; minor signs or symptoms of disease.'}.size).to eq(1)
    end

    #custom suggestions
    it "creates one 'has_karnofsky_performance_status_date' abstraction suggestion (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.select { |suggestion| suggestion.suggested_value == '2014-06-26'}.size).to eq(1)
    end

    it "creates one 'has_karnofsky_performance_status_date' abstraction suggestion source explanation (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.find { |suggestion| suggestion.suggested_value == '2014-06-26'}.abstractor_suggestion_sources.map(&:custom_explanation)).to eq(["A bit of custom logic."])
    end

    it "does not create another 'has_karnofsky_performance_status_date' abstraction suggestion upon re-abstraction (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.size).to eq(2)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.size).to eq(2)
    end

    it "does not create a'has_karnofsky_performance_status_date' abstraction 'unknown' suggestion if the custom rule makes a suggestion (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.select { |suggestion| suggestion.unknown == false }.size).to eq(1)
    end

    it "does create a'has_karnofsky_performance_status_date' abstraction 'unknown' suggestion if the custom rule does not make a suggestion (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      abstractor_abstraction_source = @abstractor_subject_abstraction_schema_kps_date.abstractor_abstraction_sources.first
      abstractor_abstraction_source.custom_method = 'empty_encounter_date'
      abstractor_abstraction_source.save!
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.size).to eq(1)
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.select { |suggestion| suggestion.unknown == true }.size).to eq(1)
    end

    #suggestion match value
    it "creates a 'has_karnofsky_performance_status' abstraction suggestion match value from a preferred name/predicate (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('karnofsky performance status: 90')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion match value from a preferred name/predicate (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('karnofsky performance status90')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion match value from a preferred name/predicate (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's karnofsky performance status is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq("the patient's karnofsky performance status is 90.")
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion match value from a predicate variant (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('kps: 90')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion match value from a predicate variant (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('kps90')
    end

    it "creates a 'has_karnofsky_performance_status' abstraction suggestion match value from a predicate variant (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq("the patient's kps is 90.")
    end

    #negation
    it "does not create a 'has_karnofsky_performance_status' abstraction suggestion match value from a negated name (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  No evidence of karnofsky performance status of 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to be_nil
    end

    it "does not create a 'has_karnofsky_performance_status' abstraction suggestion match value from a negated value (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status has no evidence of 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.match_value).to eq('karnofsky performance status')
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('karnofsky performance status has no evidence of 90.')
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.suggested_value).to be_nil
    end

    it "does not create a 'has_karnofsky_performance_status' abstraction suggestion match value from a negated name (using the sentential format) even with a negation cue not immiedatley preceeding the target value", focus: false do
      pending "Expected to fail: Need to replace the negation library with something better."

      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  No evidence of this thing called karnofsky performance status of 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to be_nil
    end

    #suggestion sources
    it "creates one 'has_karnofsky_performance_status' abstraction suggestion source given multiple identical matches (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.  Let me repeat.  KPS: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.abstractor_suggestion_sources.first.sentence_match_value == 'kps: 90'}.size).to eq(1)
    end

    it "creates one 'has_karnofsky_performance_status' abstraction suggestion source given multiple identical matches (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS90.  Let me repeat.  KPS90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.abstractor_suggestion_sources.first.sentence_match_value == 'kps90'}.size).to eq(1)
    end

    it "creates one 'has_karnofsky_performance_status' abstraction suggestion source given multiple identical matches (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.  Let me repeat.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.abstractor_suggestion_sources.first.sentence_match_value == "the patient's kps is 90."}.size).to eq(1)
    end

    it "does not create another 'has_karnofsky_performance_status' abstraction suggestion source upon re-abstraction (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(2)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(2)
    end

    it "does not create another 'has_karnofsky_performance_status' abstraction suggestion source upon re-abstraction (using the squished canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
    end

    it "does not create another 'has_karnofsky_performance_status' abstraction suggestion source upon re-abstraction (using the sentential format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
    end

    it "creates one 'has_karnofsky_performance_status_date' abstraction suggestion source (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.first.abstractor_suggestion_sources.first.custom_method).to eq('encounter_date')
    end

    it "does not create another 'has_karnofsky_performance_status_date' abstraction suggestion source upon re-abstraction (using a custom rule)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: "The patient looks healthy.  The patient's kps is 90.")
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps_date).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
    end

    #abstractor object value
    it "creates a 'has_karnofsky_performance_status' abstraction suggestion object value for each suggestion with a suggested value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      object_value = Abstractor::AbstractorObjectValue.where(value: '90% - Able to carry on normal activity; minor signs or symptoms of disease.').first
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_object_value).to eq(object_value)
    end

    #unknowns
    it "creates a 'has_karnofsky_performance_status' unknown abstraction suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.unknown).to be_truthy
    end

    it "creates a 'has_karnofsky_performance_status' unknown abstraction suggestion with a abstraction suggestion match value from a preferred name/predicate", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Not sure about his karnofsky performance status.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.unknown).to be_truthy
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.match_value).to eq("karnofsky performance status")
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq("not sure about his karnofsky performance status.")
    end

    it "creates a 'has_karnofsky_performance_status' unknown abstraction suggestion with a abstraction suggestion match value from from a predicate variant", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  His kps is probably good.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.unknown).to be_truthy
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.match_value).to eq("kps")
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq("his kps is probably good.")
    end

    it "creates a 'has_karnofsky_performance_status' unknown abstraction suggestion with a abstraction suggestion match value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  His kps is probably good.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.unknown).to be_truthy
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.match_value).to eq("kps")
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq("his kps is probably good.")
    end

    it "does not create a 'has_karnofsky_performance_status' abstraction suggestion object value for a unknown abstraction suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_object_value).to be_nil
    end

    it "does not creates another 'has_karnofsky_performance_status' unknown abstraction suggestion upon re-abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.unknown }.size).to eq(1)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.select { |suggestion| suggestion.unknown }.size).to eq(1)
    end

    it "creates a 'has_karnofsky_performance_status' unknown abstraction suggestion with a abstraction suggestion source with a match value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS is very good.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.unknown).to be_truthy
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.match_value).to eq('kps')
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('kps is very good.')
    end

    #new suggestions upon re-abstraction
    it "blanks out the current value of an abstractor abstraction if a new suggestion appears upon re-abstraction ", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_suggestion = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first
      abstractor_suggestion.accepted = true
      abstractor_suggestion.save
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).value).to eq('90% - Able to carry on normal activity; minor signs or symptoms of disease.')
      @note.note_text = 'The patient looks healthy.  KPS: 90.  Let me repeat.  KPS: 80'
      @note.save
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(4)
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).value).to be_nil
    end

    it "can create suggestions without a suggestion source", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      object_value_90 = Abstractor::AbstractorObjectValue.where(value: '90% - Able to carry on normal activity; minor signs or symptoms of disease.').first
      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      expect(abstractor_abstraction.abstractor_suggestions.size).to eq(3)
      expect(abstractor_abstraction.abstractor_suggestions.map { |abstractor_suggestion| abstractor_suggestion.abstractor_suggestion_sources }.flatten.size).to eq(4)
      expect(abstractor_abstraction.abstractor_suggestions.map { |abstractor_suggestion| abstractor_suggestion.abstractor_object_value }.flatten.compact).to match_array([object_value_90])
      object_value_80 = Abstractor::AbstractorObjectValue.where(value: '80% - Normal activity with effort; some signs or symptoms of disease.').first
      abstractor_abstraction.abstractor_subject.suggest(abstractor_abstraction, nil, nil, nil, nil, nil, nil, nil, object_value_80.value, nil, nil, nil, nil)
      expect(abstractor_abstraction.reload.abstractor_suggestions.size).to eq(4)
      expect(abstractor_abstraction.abstractor_suggestions.map { |abstractor_suggestion| abstractor_suggestion.abstractor_suggestion_sources }.flatten.size).to eq(4)
      expect(abstractor_abstraction.abstractor_suggestions.map { |abstractor_suggestion| abstractor_suggestion.abstractor_object_value }.flatten.compact).to match_array([object_value_90, object_value_80])
    end

    it "knows if it has a 'discarded' workflow_status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.save!
      end

      expect(@note_stable_identifier.reload.discarded?).to be_truthy
    end

    it "knows if it does not have a 'discarded' workflow_status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload.abstractor_abstractions.first.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED

      expect(@note_stable_identifier.reload.discarded?).to be_falsey
    end

    it "knows if it has a 'submitted' workflow_status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.save!
      end

      expect(@note_stable_identifier.reload.discarded?).to be_truthy
    end

    it "knows if it does not have a 'submitted' workflow_status", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.first.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED

      expect(@note_stable_identifier.reload.discarded?).to be_falsey
    end

    it "knows if it is 'fully set'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.save!
      end

      expect(@note_stable_identifier.reload.fully_set?).to be_truthy
    end

    it "knows if it is not 'fully set'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.abstractor_abstractions.first
      abstractor_abstraction.value ='moomin'
      @note_stable_identifier.save!

      expect(@note_stable_identifier.reload.fully_set?).to be_falsey
    end

    it 'knows a list of users who have updated its workflow status', focus: false do
      @note_1 = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
      @note_stable_identifier_1.abstract

      @note_stable_identifier_1.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.value = 'moomin'
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
        abstractor_abstraction.workflow_status_whodunnit = 'moomin'
        abstractor_abstraction.save!
      end

      @note_2 = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
      @note_stable_identifier_2.abstract

      @note_stable_identifier_2.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'littley my'
        abstractor_abstraction.save!
      end

      @note_3 = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier_3 = FactoryGirl.create(:note_stable_identifier, note: @note_3)
      @note_stable_identifier_3.abstract

      @note_stable_identifier_3.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
        abstractor_abstraction.workflow_status_whodunnit = 'littley my'
        abstractor_abstraction.save!
      end

      expect(NoteStableIdentifier.workflow_status_whodunnit_list).to eq(["littley my", "moomin"])
    end

    it 'normalizes abstractor suggestion sentences', focus: false do
      #come back need to figure out how to match on complex object
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks not so healthy.  kps: 20.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
      normalizaiton = [{
            source_type: "NoteStableIdentifier",
            source_method: "note_text",
            source_id: @note_stable_identifier.reload.abstractor_suggestion_sources[0].source_id,
            section_name: nil,
            sentences: [ { sentence: "kps: 20.", match_values: ["kps: 20."]}, { sentence: "kps: 20", match_values: ["kps: 20"]}]
      }]

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.normalize_abstractor_suggestion_sentences).to match_array(normalizaiton)
    end

    it 'normalizes abstractor suggestion sentences for overlapping matching values', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks not so healthy.  I think 20 kps 20 is correct.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.size).to eq(3)
      normalizaiton = [{
            source_type: "NoteStableIdentifier",
            source_method: "note_text",
            source_id: @note_stable_identifier.reload.abstractor_suggestion_sources[0].source_id,
            section_name: nil,
            sentences: [{sentence: "i think 20 kps 20 is correct.", match_values: ["i think 20 kps 20 is correct."]}]
      }]

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first.normalize_abstractor_suggestion_sentences).to eq(normalizaiton)
    end

    it 'creates a relationship to its accepted object value', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks not so healthy.  I think 20 kps 20 is correct.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      expect(abstractor_abstraction.abstractor_object_value).to be_nil
      abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
        if abstractor_suggestion.suggested_value.present?
          abstractor_suggestion.accepted = true
          abstractor_suggestion.save!
        end
      end
      expect(abstractor_abstraction.reload.abstractor_object_value).to_not be_nil
    end

    it 'removes the relationship to its unaccepted object value', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks not so healthy.  I think 20 kps 20 is correct.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps)
      expect(abstractor_abstraction.abstractor_object_value).to be_nil
      abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
        if abstractor_suggestion.suggested_value.present?
          abstractor_suggestion.accepted = true
          abstractor_suggestion.save!
        end
      end

      expect(abstractor_abstraction.reload.abstractor_object_value).to_not be_nil

      abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save!
      end
      expect(abstractor_abstraction.reload.abstractor_object_value).to be_nil
    end

    describe "querying by abstractor abstraction status" do
      before(:each) do
        @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  KPS: 90.')
        @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
        @note_stable_identifier.abstract
        @note_stable_identifier.reload
      end

      it "can report what needs to be reviewed", focus: false do
        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW)).to eq([@note_stable_identifier])
      end

      it "can report what needs to be reviewed (ignoring soft deleted rows)", focus: false do
        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW)).to  eq([@note_stable_identifier])

        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.soft_delete!
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW)).to be_empty
      end

      it "can report what needs to be reviewed (including 'blanked' values)", focus: false do
        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW)).to eq([@note_stable_identifier])

        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          expect(abstractor_abstraction.value).to be_nil
          abstractor_abstraction.value = ''
          abstractor_abstraction.save!
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW)).to eq([@note_stable_identifier])
      end

      it "can report what has been reviewed (including 'blanked' values)", focus: false do
        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW)).to eq([@note_stable_identifier])

        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          expect(abstractor_abstraction.value).to be_nil
          abstractor_abstraction.value = ''
          abstractor_abstraction.save!
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED)).to eq([])
      end

      it "can report what has been reviewed", focus: false do
        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
          abstractor_suggestion.accepted = true
          abstractor_suggestion.save
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED)).to eq([@note_stable_identifier])
      end

      it "can report what has been reviewed (ignoring soft deleted rows)", focus: false do
        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
          abstractor_suggestion.accepted = true
          abstractor_suggestion.save
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED)).to eq([@note_stable_identifier])

        @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.soft_delete!
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED)).to be_empty
      end

      it "can report what has been actually answered", focus: false do
        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.value = 'foo'
          abstractor_abstraction.save
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_ACTUALLY_ANSWERED)).to eq([@note_stable_identifier])
      end

      it "can report what has not been actually answered (looking for unknowns)", focus: false do
        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.unknown = true
          abstractor_abstraction.save
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_ACTUALLY_ANSWERED)).to be_empty
      end

      it "can report what has not been actually answered (looking for not applicable)", focus: false do
        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.not_applicable = true
          abstractor_abstraction.save
        end

        expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_ACTUALLY_ANSWERED)).to be_empty
      end

      it "can report what needs to be reviewed for an instance", focus: false do
        expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW).size).to eq(7)
      end

      it "can report what has been reviewed for an instance", focus: false do
        abstractor_suggestion = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save

        expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED).size).to eq(1)
      end

      it "can report what needs to be reviewed for an instance (ignoring soft deleted rows)", focus: false do
        expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW).size).to eq(7)
        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.soft_delete!
        end
        expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW).size).to eq(0)
      end

      it "can report what has been reviewed for an instance (ignoring soft deleted rows)", focus: false do
        abstractor_suggestion = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_kps).abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save

        expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED).size).to eq(1)

        @note_stable_identifier.abstractor_abstractions.each do |abstractor_abstraction|
          abstractor_abstraction.soft_delete!
        end
        expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED).size).to eq(0)
      end
    end

    #pivioting
    it "can pivot abstractions as if regular columns on the abstractable entity", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      pivot = NoteStableIdentifier.pivot_abstractions.where(id: @note_stable_identifier.id).map { |n| { id: n.id, note_text: n.note_text, has_karnofsky_performance_status: n.has_karnofsky_performance_status } }
      expect(pivot).to eq([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note_text, has_karnofsky_performance_status: "90% - Able to carry on normal activity; minor signs or symptoms of disease." }])
    end

    it "can pivot abstractions as if regular columns on the abstractable entity if the vaue is marked as 'unknown'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.unknown = true
        abstractor_abstraction.save!
      end

      pivot = NoteStableIdentifier.pivot_abstractions.where(id: @note_stable_identifier.id).map { |n| { id: @note_stable_identifier.id, note_text: @note_stable_identifier.note_text, has_karnofsky_performance_status: n.has_karnofsky_performance_status } }
      expect(pivot).to eq([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note_text, has_karnofsky_performance_status: 'unknown' }])
    end

    it "can pivot abstractions as if regular columns on the abstractable entity if the vaue is marked as 'not applicable'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.not_applicable = true
        abstractor_abstraction.save!
      end

      pivot = NoteStableIdentifier.pivot_abstractions.where(id: @note_stable_identifier.id).map { |n| { id: n.id, note_text: n.note_text, has_karnofsky_performance_status: n.has_karnofsky_performance_status } }
      expect(pivot).to eq([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note_text, has_karnofsky_performance_status: 'not applicable' }])
    end

    it "can pivot abstractions as if regular columns on the abstractable entity (even if the entity has not been abstracted)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)

      pivot = NoteStableIdentifier.pivot_abstractions.where(id: @note_stable_identifier.id).map { |n| { id: n.id, note_text: n.note_text, has_karnofsky_performance_status: n.has_karnofsky_performance_status } }
      expect(pivot).to eq([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note_text, has_karnofsky_performance_status: nil }])
    end

    it 'can generate a unique set of sources across all its abstractions', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Karnofsky performance status: 90.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      sources = [{:source_type=>
          NoteStableIdentifier,
         :source_id=> @note_stable_identifier.reload.abstractor_suggestion_sources[0].source_id,
         :source_method=>"note_text",
         :section_name=>nil,
         :abstractor_suggestion_sources=>
          [{:source_type=>
             NoteStableIdentifier,
            :source_id=>@note_stable_identifier.reload.abstractor_suggestion_sources[1].source_id,
            :source_method=>"note_text",
            :section_name=>nil,
            :sentence_match_value=>nil},
            {:source_type=>
             NoteStableIdentifier,
            :source_id=>@note_stable_identifier.reload.abstractor_suggestion_sources[2].source_id,
            :source_method=>"note_text",
            :section_name=>nil,
            :sentence_match_value=>"karnofsky performance status: 90."},
           {:source_type=>
             NoteStableIdentifier,
            :source_id=>@note_stable_identifier.reload.abstractor_suggestion_sources[3].source_id,
            :source_method=>"note_text",
            :section_name=>nil,
            :sentence_match_value=>"karnofsky performance status: 90"}
           ]}]

      expect(@note_stable_identifier.reload.sources.first[:source_id]).to eq(sources.first[:source_id])
      expect(@note_stable_identifier.reload.sources.first[:source_medthod]).to eq(sources.first[:source_medthod])
      expect(@note_stable_identifier.reload.sources.first[:section_name]).to eq(sources.first[:section_name])
      expect(@note_stable_identifier.reload.sources.size).to eq(sources.size)
      expect(@note_stable_identifier.reload.sources.first[:abstractor_suggestion_sources]).to match_array(sources.first[:abstractor_suggestion_sources])
    end

    describe 'grouped abstractions' do
      before(:each) do
        @family_subject_group  = Abstractor::AbstractorSubjectGroup.where(name: 'Family history of movement disorder', subtype: Abstractor::Enum::ABSTRACTOR_GROUP_SENTENTIAL_SUBTYPE).first_or_create
        items_count = 0

        @relative_abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where( predicate: 'has_relative_with_movement_disorder_relative', display_name: 'Relative', abstractor_object_type: @list_object_type, preferred_name: 'Relative').first_or_create
        abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Biological Mother', vocabulary_code: 'Biological Mother').first_or_create
        ['mother','mom'].each do |variant|
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: variant).first_or_create
        end
        Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value).first_or_create

        abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'Biological Father', vocabulary_code: 'Biological Father').first_or_create
        ['father','dad'].each do |variant|
          Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: variant).first_or_create
        end

        Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: @relative_abstractor_abstraction_schema,abstractor_object_value: abstractor_object_value).first_or_create
        ['Full', 'Half'].each do |value|
          abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: "#{value} Sibling", vocabulary_code: "#{value} Sibling").first_or_create
          ['sister', 'sisters', 'brother', 'brothers', 'sibling', 'siblings'].each do |variant|
            if value == 'Full'
              Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: variant).first_or_create
            else
              Abstractor::AbstractorObjectValueVariant.where(abstractor_object_value: abstractor_object_value, value: value + ' ' + variant).first_or_create
            end
          end
          Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: @relative_abstractor_abstraction_schema,abstractor_object_value: abstractor_object_value).first_or_create
        end

        abstractor_subject = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)

        items_count = items_count + 1
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        @disorder_abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where( predicate: 'has_relative_with_movement_disorder_disorder', display_name: 'Disorder', abstractor_object_type: @list_object_type, preferred_name: 'Disorder').first_or_create

        ['parkinsonism', 'tremor', 'Essential tremor', 'pd'].each do |value|
          abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: value, vocabulary_code: value).first_or_create
          Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema,abstractor_object_value: abstractor_object_value).first_or_create
        end

        abstractor_subject = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)

        items_count = items_count + 1
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create
      end

      it 'detects sentential groups', focus: false do
        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
        @note_stable_identifier_1.abstract

        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 3
        abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq @family_subject_group.abstractor_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
        @note_stable_identifier_2.abstract

        expect(Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).count).to eq 6

        # first abstracted note should be intact
        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 3
        abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq @family_subject_group.abstractor_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # second abstracted note should have a full set of abstractions
        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 3
        abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq @family_subject_group.abstractor_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end
      end

      it 'removes unused abstractions', focus: false do
        note_text = "Mother - died age 70, cardiac problems, no neurologic problem\nFather - died age 75, \"PD\" diagnosis, had abnormal movements in his 70s"
        @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
        @note_stable_identifier_1.abstract

        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 1

        expect(Abstractor::AbstractorAbstraction.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).length).to eq 2
      end

      it 're-abstracts sentential groups', focus: false do
        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
        @note_stable_identifier_1.abstract

        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 3
        abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq @family_subject_group.abstractor_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
        @note_stable_identifier_2.abstract

        # first abstracted note should be intact
        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 3
        abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq @family_subject_group.abstractor_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # second abstracted note should have a full set of abstractions
        abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
        expect(abstractor_abstraction_groups.count).to eq 3
        abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq @family_subject_group.abstractor_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end
      end

      it 'respects namespacing in sentential groups', focus: false do
        items_count = 0
        abstractor_subject_1_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        items_count = items_count + 1
        abstractor_subject_1_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        items_count = 0
        abstractor_subject_2_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        items_count = items_count + 1
        abstractor_subject_2_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        namespace_1_subjects = @family_subject_group.abstractor_subjects.where(namespace_type: 'Discerner::Search', namespace_id: 1)
        namespace_2_subjects = @family_subject_group.abstractor_subjects.where(namespace_type: 'Discerner::Search', namespace_id: 2)


        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
        # abstract first note in first namespace
        @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

        # total number of groups
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 3

        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 0

        # abstract first note in second namespace
        @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        # first namespace should not be affected
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # additional set of abstractions in namespace 2
        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
        # abstract second note in first namespace
        @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

        # first note should not be affected
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        # first namespace should not be affected
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # second note should have a full set of abstractions in the first namespace
        # total number of groups
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 3

        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 0

        # abstract second note in second namespace
        @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)
        # first note should not be affected
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        # first namespace should not be affected
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # first namespace should not be affected
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id).any?}
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # second note should have an additional full set of abstractions
        # total number of groups
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end
      end

      it 're-abstracts namespaced sentential groups', focus: false do
        items_count = 0
        abstractor_subject_1_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        items_count = items_count + 1
        abstractor_subject_1_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        items_count = 0
        abstractor_subject_2_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        items_count = items_count + 1
        abstractor_subject_2_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
        Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
        Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

        namespace_1_subjects = @family_subject_group.abstractor_subjects.where(namespace_type: 'Discerner::Search', namespace_id: 1)
        namespace_2_subjects = @family_subject_group.abstractor_subjects.where(namespace_type: 'Discerner::Search', namespace_id: 2)

        # abstract first note in first namespace
        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
        @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
        @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

        # total number of groups
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 3

        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 0

        # abstract first note in second namespace
        @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)
        @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        # first namespace should not be affected
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # additional set of abstractions in namespace 2
        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        note_text = "Family Hx: Mother - died from CHF, dementia in later years; Dad - pancreatic cancer , DM 2 sisters with DM, 1 of those with schizophrenia. Dad and sister with parkinsonism. DM, MI in siblings.\nHer father had a tremor and was diagnosed with parkinsonism. He was not treated for it. She also has a sister who lives in nursing home that has asymmetric tremor and suspected parkinsonism, but is not being treated either. Of note, she also has a hx of schizophrenia that is being treated with AP."
        @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
        @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)

        # abstract second note in first namespace
        @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)
        @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

        # first note should not be affected
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        # first namespace should not be affected
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # second note should have a full set of abstractions in the first namespace
        # total number of groups
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 3

        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 0

        # abstract second note in second namespace
        @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)
        @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)
        # first note should not be affected
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        # first namespace should not be affected
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # first namespace should not be affected
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id).any?}
        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        # second note should have an additional full set of abstractions
        # total number of groups
        all_abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id).any?}
        expect(all_abstractor_abstraction_groups.count).to eq 6

        namespace_1_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_1_subjects.map(&:id)).any?}
        expect(namespace_1_abstractor_abstraction_groups.count).to eq 3
        namespace_1_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end

        namespace_2_abstractor_abstraction_groups = all_abstractor_abstraction_groups.select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(abstractor_subject_id: namespace_2_subjects.map(&:id)).any?}
        expect(namespace_2_abstractor_abstraction_groups.count).to eq 3
        namespace_2_abstractor_abstraction_groups.each do |abstractor_abstraction_group|
          expect(abstractor_abstraction_group.abstractor_abstractions.length).to eq namespace_1_subjects.length

          abstractor_suggestion_sources = Abstractor::AbstractorSuggestionSource.joins(abstractor_suggestion: { abstractor_abstraction: :abstractor_abstraction_group})
            .where(abstractor_abstraction_groups: { id: abstractor_abstraction_group.id}, abstractor_suggestions: { unknown: false })

          expect(abstractor_suggestion_sources.select(:sentence_match_value).distinct.map(&:sentence_match_value).length).to eq 1
        end
      end

      describe 'it leaves default group intact' do
        it 'if no sentential subgroups detected', focus: false do
          note_text = "Hello, world"
          @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
          @note_stable_identifier_1.abstract

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
          @note_stable_identifier_2.abstract

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1
        end

        it 'if no complete sentential subgroups detected', focus: false do
          note_text = "Hello, father"
          @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
          @note_stable_identifier_1.abstract

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
          @note_stable_identifier_2.abstract

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1
        end

        it 'respects namespacing in sentential groups if no sentential subgroups detected', focus: false do
          items_count = 0
          abstractor_subject_1_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          items_count = items_count + 1
          abstractor_subject_1_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          items_count = 0
          abstractor_subject_2_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          items_count = items_count + 1
          abstractor_subject_2_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          note_text = "Hello, world"
          @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
          @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2

          @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
          @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)
          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2
        end

        it 'respects namespacing in sentential groups if no complete sentential subgroups detected', focus: false do
          items_count = 0
          abstractor_subject_1_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          items_count = items_count + 1
          abstractor_subject_1_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_1_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_1_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          items_count = 0
          abstractor_subject_2_1 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @relative_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_1, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_1, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          items_count = items_count + 1
          abstractor_subject_2_2 = Abstractor::AbstractorSubject.where( subject_type: 'NoteStableIdentifier', abstractor_abstraction_schema: @disorder_abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2).first_or_create
          Abstractor::AbstractorAbstractionSource.create(abstractor_subject: abstractor_subject_2_2, from_method: 'note_text', abstractor_abstraction_source_type: @source_type_nlp_suggestion, abstractor_rule_type: @value_rule)
          Abstractor::AbstractorSubjectGroupMember.where(abstractor_subject: abstractor_subject_2_2, abstractor_subject_group: @family_subject_group, display_order: items_count).first_or_create

          note_text = "Hello, father"
          @note_1 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_1 = FactoryGirl.create(:note_stable_identifier, note: @note_1)
          @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          @note_stable_identifier_1.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2

          @note_2 = FactoryGirl.create(:note, person: @person, note_text: note_text)
          @note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: @note_2)
          @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 1)

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 1

          @note_stable_identifier_2.abstract(namespace_type: 'Discerner::Search', namespace_id: 2)
          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_1.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2

          abstractor_abstraction_groups = Abstractor::AbstractorAbstractionGroup.where(abstractor_subject_group_id: @family_subject_group.id).select{|abstractor_abstraction_group| abstractor_abstraction_group.abstractor_abstractions.where(about_id: @note_stable_identifier_2.id, abstractor_subject_id: @family_subject_group.abstractor_subjects.map(&:id)).any?}
          expect(abstractor_abstraction_groups.count).to eq 2
        end
      end
    end
  end
end