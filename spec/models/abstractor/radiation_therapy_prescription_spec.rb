require 'rails_helper'
describe NoteStableIdentifier do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.radiation_therapy_prescription
    @abstractor_abstraction_schema_has_anatomical_location = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_anatomical_location').first
    @abstractor_abstraction_schema_has_laterality = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_laterality').first
    @abstractor_abstraction_schema_has_radiation_therapy_prescription_date = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_radiation_therapy_prescription_date').first
    @abstractor_subject_abstraction_schema_has_anatomical_location = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_has_anatomical_location.id).first
    @abstractor_subject_abstraction_schema_has_laterality = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_has_laterality.id).first
    @abstractor_subject_abstraction_schema_has_radiation_therapy_prescription_date = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_has_radiation_therapy_prescription_date.id).first
    @anatomical_location_subject_group  = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first

    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  before(:each) do
    @note = FactoryGirl.create(:note, person: @person)
    @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
  end

  describe "abstracting" do
    it "can report its abstractor subject groups", focus: false do
      abstractor_subject_groups = Abstractor::AbstractorSubjectGroup.where(name:'Anatomical Location')
      expect(NoteStableIdentifier.abstractor_subject_groups).to_not be_empty
      expect(Set.new(NoteStableIdentifier.abstractor_subject_groups)).to eq(Set.new(abstractor_subject_groups))
    end

    #abstractions
    it "creates a 'has_anatomical_location' abstraction'", focus: false do
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location)).to_not be_nil
    end

    it "does not create another 'has_anatomical_location' abstraction upon re-abstraction", focus: false do
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.abstractor_abstractions.select { |abstraction| abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_anatomical_location' }.size).to eq(1)
    end

    it "creates a 'has_laterality' abstraction'", focus: false do
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_laterality)).to_not be_nil
    end

    it "does not create another 'has_laterality' abstraction upon re-abstraction", focus: false do
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.abstractor_abstractions.select { |abstractor_abstraction| abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_laterality' }.size).to eq(1)
    end

    #suggestion suggested value
    it "creates a 'has_anatomical_location' abstraction suggestion suggested value from an abstractor object value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.suggested_value).to eq('parietal lobe')
    end

    it "creates a 'has_anatomical_location' abstraction suggestion suggested value from an abstractor object value variant", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.suggested_value).to eq('parietal lobe')
    end

    it "creates an association to the abstractor object value variant for a 'has_anatomical_location' abstraction suggestion suggested value from an abstractor object value variant", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location)
      abstractor_object_value = @abstractor_abstraction_schema_has_anatomical_location.abstractor_object_values.where(value: 'parietal lobe').first
      abstractor_object_value_variant = abstractor_object_value.abstractor_object_value_variants.where(value: 'parietal').first
      expect(abstractor_abstraction.abstractor_suggestions.first.abstractor_object_value_variants.first).to eq(abstractor_object_value_variant)
    end

    it "creates an association to the abstractor object value variant for a 'has_anatomical_location' abstraction suggestion suggested value from an abstractor object value variant (but only one)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Look at the cerebral cortex.  My goodness that is the Cerebral cortex.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location)
      abstractor_object_value = @abstractor_abstraction_schema_has_anatomical_location.abstractor_object_values.where(value: 'cerebrum').first
      abstractor_object_value_variant = abstractor_object_value.abstractor_object_value_variants.where(value: 'cerebral cortex').first
      expect(abstractor_abstraction.abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(2)
      expect(abstractor_abstraction.abstractor_suggestions.first.abstractor_object_value_variants).to match_array([abstractor_object_value_variant])
    end

    it "creates an association to multiple abstractor object value variants for a 'has_anatomical_location' abstraction suggestion suggested value from multiple abstractor object value variants", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Look at the cerebral cortex.  My goodness that is the internal capsule.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location)
      abstractor_object_value = @abstractor_abstraction_schema_has_anatomical_location.abstractor_object_values.where(value: 'cerebrum').first
      abstractor_object_value_variant_1 = abstractor_object_value.abstractor_object_value_variants.where(value: 'cerebral cortex').first
      abstractor_object_value_variant_2 = abstractor_object_value.abstractor_object_value_variants.where(value: 'internal capsule').first
      expect(abstractor_abstraction.abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(2)
      expect(abstractor_abstraction.abstractor_suggestions.first.abstractor_object_value_variants).to match_array([abstractor_object_value_variant_1, abstractor_object_value_variant_2])
    end

    it "creates an association to the abstractor object value variant for a 'has_anatomical_location' abstraction suggestion suggested value from an abstractor object value variant case insensitively", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left PARIETAL')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstraction = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location)
      abstractor_object_value = @abstractor_abstraction_schema_has_anatomical_location.abstractor_object_values.where(value: 'parietal lobe').first
      abstractor_object_value_variant = abstractor_object_value.abstractor_object_value_variants.where(value: 'parietal').first
      expect(abstractor_abstraction.abstractor_suggestions.first.abstractor_object_value_variants.first).to eq(abstractor_object_value_variant)
    end

    it "creates a 'has_anatomical_location' abstraction suggestion suggested value from an abstractor object value variant even if another synonym for the same term is negated", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Not in the thalamus.  But I think it is in the basal ganglia.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.suggested_value).to eq('cerebrum')
    end

    #suggestion match value
    it "creates a 'has_anatomical_location' abstraction suggestion match value from a from an abstractor object value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('left parietal lobe')
    end

    it "creates a 'has_anatomical_location' abstraction suggestion match value from a from an abstractor object value variant", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to eq('left parietal')
    end

    it "creates multiple 'has_anatomical_location' abstraction suggestion match values given multiple different matches", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Left parietal lobe.  Let me remind you that it is the left parietal.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(Set.new(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value))).to eq(Set.new(["left parietal lobe.", "let me remind you that it is the left parietal."]))
    end

    #suggestions
    it "does not create another 'has_anatomical_location' abstraction suggestion upon re-abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.size).to eq(3)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.size).to eq(3)
    end

    it "creates multiple 'has_anatomical_location' abstraction suggestions given multiple different matches", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe and bilateral cerebral meninges')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(Set.new(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.map(&:suggested_value).compact)).to eq(Set.new(['cerebral meninges', 'parietal lobe', 'meninges']))
    end

    it "creates one 'has_anatomical_location' abstraction suggestion given multiple identical matches", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Left parietal lobe.  Let me remend you that it is the left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.select { |abstractor_suggestion| abstractor_suggestion.suggested_value == 'parietal lobe'}.size).to eq(1)
    end

    #negation
    it "does not create a 'has_anatomical_location' abstraction suggestion match value from a negated value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Not the left parietal lobe.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_suggestion_sources.first.sentence_match_value).to be_nil
    end

    #suggestion sources
    it "creates one 'has_anatomical_location' abstraction suggestion source given multiple identical matches", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Left parietal lobe.  Talk about some other stuff.  Left parietal lobe.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.select { |abstractor_suggestion| abstractor_suggestion.abstractor_suggestion_sources.first.sentence_match_value == 'left parietal lobe.'}.size).to eq(1)
    end

    it "does not create another 'has_anatomical_location' abstraction suggestion source upon re-abstraction (using the canonical name/value format)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_suggestion_sources.size).to eq(1)
    end

    #abstractor object value
    it "creates a 'has_anatomical_location' abstraction suggestion object value for each suggestion with a suggested value", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_object_value = Abstractor::AbstractorObjectValue.where(value: 'parietal lobe').first
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_object_value).to eq(abstractor_object_value)
    end

    #unknowns
    it "creates a 'has_anatomical_location' unknown abstraction suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Forgot to mention an anatomical location.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.unknown).to be_truthy
    end

    it "does not create a 'has_anatomical_location' abstraction suggestion object value for a unknown abstraction suggestion", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Forgot to mention an anatomical location.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.first.abstractor_object_value).to be_nil
    end

    it "does not creates another 'has_anatomical_location' unknown abstraction suggestion upon re-abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'Forgot to mention an anatomical location.')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.select { |abstractor_suggestion| abstractor_suggestion.unknown }.size).to eq(1)
      @note_stable_identifier.abstract
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_has_anatomical_location).abstractor_suggestions.select { |abstractor_suggestion| abstractor_suggestion.unknown }.size).to eq(1)
    end

    #groups
    it "creates a abstractor abstraction group", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.size).to eq(1)
    end

    it "does not creates another abstractor abstraction group upon re-abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
      @note_stable_identifier.reload.abstract
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.size).to eq(1)
    end

    it "creates a abstractor abstraction group member for each abstractor abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.first.abstractor_abstractions.size).to eq(3)
    end

    it "does not create duplicate abstractor abstraction grup members upon re-abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract
      @note_stable_identifier.reload.abstract

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.first.abstractor_abstractions.size).to eq(3)
    end

    it "creates a abstractor abstraction group member of the right kind for each abstractor abstraction", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
      expect(Set.new(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.first.abstractor_abstractions.map(&:abstractor_abstraction_schema))).to eq(Set.new([@abstractor_abstraction_schema_has_anatomical_location, @abstractor_abstraction_schema_has_laterality, @abstractor_abstraction_schema_has_radiation_therapy_prescription_date]))
    end

    describe "updating all abstraction group members" do
      before(:each) do
        @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
        @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
        @note_stable_identifier.abstract

        abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
        @abstractor_abstraction_group = @note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.first
      end

      it "to 'not applicable'", focus: false do
        expect(@abstractor_abstraction_group.abstractor_abstractions.map(&:not_applicable)).to eq([nil, nil, nil])
        Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value(@abstractor_abstraction_group.abstractor_abstractions, Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_NOT_APPLICABLE)
        expect(@abstractor_abstraction_group.reload.abstractor_abstractions.map(&:not_applicable)).to eq([true, true, true])
      end

      it "to 'unknown'", focus: false do
        expect(@abstractor_abstraction_group.abstractor_abstractions.map(&:unknown)).to eq([nil, nil, nil])
        Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value(@abstractor_abstraction_group.abstractor_abstractions, Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_UNKNOWN)
        expect(@abstractor_abstraction_group.reload.abstractor_abstractions.map(&:unknown)).to eq([true, true, true])
      end

      it "does not update more than necessary", focus: false do
        PaperTrail.enabled = true
        @note = FactoryGirl.create(:note, person: @person, note_text: 'vague blather')
        @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
        @note_stable_identifier.abstract

        abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Anatomical Location').first
        abstractor_abstraction_group = @note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.first

        expect(abstractor_abstraction_group.abstractor_abstractions.map{ |aa| aa.versions.size }).to eq([1,1,1])
        Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value(abstractor_abstraction_group.reload.abstractor_abstractions, Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_UNKNOWN)
        Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value(abstractor_abstraction_group.reload.abstractor_abstractions, Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_NOT_APPLICABLE)
        pending "Expected to fail: Need to figure out if this is a problem."
        expect(abstractor_abstraction_group.abstractor_abstractions.map{ |aa| aa.versions.size }).to eq([4,4,4])
        PaperTrail.enabled = false
      end

      it "rejects all abstraction suggestion statuses", focus: false do
        # rejected_status = Abstractor::AbstractorSuggestionStatus.where(:name => 'Rejected').first
        # needs_review_status = Abstractor::AbstractorSuggestionStatus.where(:name => 'Needs review').first
        abstractor_suggestions = @abstractor_abstraction_group.abstractor_abstractions.map(&:abstractor_suggestions).flatten
        expect(abstractor_suggestions.map(&:accepted)).to eq([nil, nil, nil, nil, nil, nil, nil])
        Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value(@abstractor_abstraction_group.abstractor_abstractions, Abstractor::Enum::ABSTRACTION_OTHER_VALUE_TYPE_NOT_APPLICABLE)
        expect(abstractor_suggestions.each(&:reload).map(&:accepted)).to eq([false, false, true, false, false, true, false])
      end

      it "raises an error if passed an invalid argument", focus: false do
        expect{ Abstractor::AbstractorAbstraction.update_abstractor_abstraction_other_value('little my') }.to raise_error(ArgumentError)
      end
    end

    #pivoting groups
    it "can pivot grouped abstractions as if regular columns on the abstractable entity", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name:'Anatomical Location').first
      abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: abstractor_subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)

      abstractor_subject_group.abstractor_subjects.each do |abstractor_subject|
        abstraction = abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
        abstractor_abstraction_group.abstractor_abstractions << abstraction
      end
      abstractor_abstraction_group.save!

      pivots = NoteStableIdentifier.pivot_grouped_abstractions('Anatomical Location').where(id: @note_stable_identifier.id).map { |rtp| { id: rtp.id, note_text: rtp.note.note_text, has_laterality: rtp.has_laterality, has_anatomical_location: rtp.has_anatomical_location } }
      expect(Set.new(pivots)).to eq(Set.new([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note.note_text, has_laterality: "left", has_anatomical_location: "parietal lobe" }, { id: @note_stable_identifier.id, note_text: @note_stable_identifier.note.note_text, has_laterality: nil, has_anatomical_location: nil }]))
    end

    it "can pivot grouped abstractions as if regular columns on the abstractable entity if the value is marked as 'unknown'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.unknown = true
        abstractor_abstraction.save!
      end

      pivots = NoteStableIdentifier.pivot_grouped_abstractions('Anatomical Location').where(id: @note_stable_identifier.id).map { |rtp| { id: rtp.id, note_text: rtp.note.note_text, has_laterality: rtp.has_laterality, has_anatomical_location: rtp.has_anatomical_location } }
      expect(Set.new(pivots)).to eq(Set.new([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note.note_text, has_laterality: 'unknown', has_anatomical_location: 'unknown' } ]))
    end

    it "can pivot grouped abstractions as if regular columns on the abstractable entity if the value is marked as 'not applicable'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.not_applicable = true
        abstractor_abstraction.save!
      end

      pivots = NoteStableIdentifier.pivot_grouped_abstractions('Anatomical Location').where(id: @note_stable_identifier.id).map { |rtp| { id: rtp.id, note_text: rtp.note.note_text, has_laterality: rtp.has_laterality, has_anatomical_location: rtp.has_anatomical_location } }
      expect(Set.new(pivots)).to eq(Set.new([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note.note_text, has_laterality: 'not applicable', has_anatomical_location: 'not applicable' } ]))
    end

    describe "a mix of grouped and non-grouped abstractions" do
      before(:each) do
        string_object_type = Abstractor::AbstractorObjectType.where(value: 'string').first
        unknown_rule = Abstractor::AbstractorRuleType.where(name: 'unknown').first
        moomin_abstraction_schema = Abstractor::AbstractorAbstractionSchema.create(predicate: 'has_moomin', display_name: 'Moomin', abstractor_object_type: string_object_type, preferred_name: 'Moomin')
        abstractor_subject = Abstractor::AbstractorSubject.create(:subject_type => NoteStableIdentifier.to_s, :abstractor_abstraction_schema => moomin_abstraction_schema)
        @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
        @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      end

      it "does not include grouped abstractions when pivoting non-grouped abstractions", focus: false do
        pivots = NoteStableIdentifier.pivot_abstractions.where(id: @note_stable_identifier.id)
        expect(pivots.first).to respond_to(:has_moomin)
        expect(pivots.first).not_to respond_to(:has_laterality)
        expect(pivots.first).not_to respond_to(:has_anatomical_location)
      end

      it "does not include non-grouped abstractions when pivoting grouped abstractions", focus: false do
        @note_stable_identifier.abstract
        pivots = NoteStableIdentifier.pivot_grouped_abstractions('Anatomical Location').where(id: @note_stable_identifier.id)
        expect(pivots.first).not_to respond_to(:has_moomin)
        expect(pivots.first).to respond_to(:has_laterality)
        expect(pivots.first).to respond_to(:has_anatomical_location)
      end

      # abstractor subjects
      it "reports all abstractor subjects if the grouped options is not specified", focus: false do
        expect(NoteStableIdentifier.abstractor_subjects.size).to eq(4)
      end

      it "can report its grouped abstractor subjects", focus: false do
        expect(NoteStableIdentifier.abstractor_subjects(grouped: true).size).to eq(3)
      end

      it "can report its ungrouped abstractor subjects", focus: false do
        expect(NoteStableIdentifier.abstractor_subjects(grouped: false).size).to eq(1)
      end

      # abstraction schemas
      it "reports all abstractor subjects if the grouped options is not specified", focus: false do
        expect(NoteStableIdentifier.abstractor_abstraction_schemas.size).to eq(4)
      end

      it "can report its grouped abstraction schemas ", focus: false do
        expect(NoteStableIdentifier.abstractor_abstraction_schemas(grouped: true).size).to eq(3)
      end

      it "can report its ungrouped abstractor subjects", focus: false do
        expect(NoteStableIdentifier.abstractor_abstraction_schemas(grouped: false).size).to eq(1)
      end
    end

    it 'creates an abstraction group', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(1)

      Abstractor::AbstractorAbstractionGroup.create_abstractor_abstraction_group(@anatomical_location_subject_group.id, NoteStableIdentifier.to_s, @note_stable_identifier.id, nil, nil)
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(2)
    end

    it 'creates an abstraction group', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(1)

      Abstractor::AbstractorAbstractionGroup.create_abstractor_abstraction_group(@anatomical_location_subject_group.id, NoteStableIdentifier.to_s, @note_stable_identifier.id, nil, nil)
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(2)
    end

    it 'copies suggestions from the initial group when creating an abstraction group', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(1)

      Abstractor::AbstractorAbstractionGroup.create_abstractor_abstraction_group(@anatomical_location_subject_group.id, NoteStableIdentifier.to_s, @note_stable_identifier.id, nil, nil)
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(2)

      suggestions_1 = @note_stable_identifier.abstractor_abstraction_groups.first.abstractor_abstractions.map(&:abstractor_suggestions).flatten
      suggestions_2 = @note_stable_identifier.abstractor_abstraction_groups.last.abstractor_abstractions.map(&:abstractor_suggestions).flatten
      expect(suggestions_1.size).to eq(suggestions_2.size)
      expect(suggestions_1.map(&:suggested_value)).to match_array(suggestions_2.map(&:suggested_value))
    end

    it 'finds abstractions by abstraction schema', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      abstractor_abstractions = @note_stable_identifier.abstractor_abstractions.select { |abstractor_abstraction| abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema == @abstractor_abstraction_schema_has_anatomical_location }
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstraction_schemas(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_anatomical_location.id])).to_not be_empty
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstraction_schemas(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_anatomical_location.id])).to eq(abstractor_abstractions)
    end

    it 'finds abstractions by abstraction schema within an abstraction group', focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'left parietal lobe')
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract

      Abstractor::AbstractorAbstractionGroup.create_abstractor_abstraction_group(@anatomical_location_subject_group.id, NoteStableIdentifier.to_s, @note_stable_identifier.id, nil, nil)
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(2)
      astractor_abstraction_group_1 = @note_stable_identifier.abstractor_abstraction_groups.first
      astractor_abstraction_group_2 = @note_stable_identifier.abstractor_abstraction_groups.last
      abstractor_abstractions_group_1 = astractor_abstraction_group_1.abstractor_abstractions.select { |abstractor_abstraction| abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema == @abstractor_abstraction_schema_has_anatomical_location }.first
      abstractor_abstractions_group_2 = astractor_abstraction_group_2.abstractor_abstractions.select { |abstractor_abstraction| abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema == @abstractor_abstraction_schema_has_anatomical_location }.first
      expect([abstractor_abstractions_group_1]).to_not be_empty
      expect([abstractor_abstractions_group_2]).to_not be_empty
      expect(abstractor_abstractions_group_1).to_not eq (abstractor_abstractions_group_2)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstraction_schemas(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_anatomical_location.id], abstractor_abstraction_group: astractor_abstraction_group_1).first).to eq(abstractor_abstractions_group_2)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstraction_schemas(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_anatomical_location.id], abstractor_abstraction_group: astractor_abstraction_group_2).last).to eq(abstractor_abstractions_group_1)
    end
  end
end