require 'rails_helper'
describe NoteStableIdentifier do
  before(:each) do
    Abstractor::Setup.system
    OmopAbstractor::SpecSetup.sites
    OmopAbstractor::SpecSetup.custom_site_synonyms
    OmopAbstractor::SpecSetup.site_categories
    OmopAbstractor::SpecSetup.laterality
    OmopAbstractor::SpecSetup.imaging_exam
    @abstractor_namespace_imaging_exams_1 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 1', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create
    @abstractor_namespace_imaging_exams_2 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 2', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create
    @abstractor_namespace_imaging_exams_3 = Abstractor::AbstractorNamespace.where(name: 'Imaging Exams 3', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create

    @abstractor_abstraction_schema_moomin_major = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_favorite_major_moomin_character').first
    @abstractor_subject_abstraction_schema_moomin_major = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_moomin_major.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id).first

    @abstractor_abstraction_schema_moomin_minor = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_favorite_minor_moomin_character').first
    @abstractor_subject_abstraction_schema_moomin_minor = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_moomin_minor.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id).first

    @abstractor_abstraction_schema_dat = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_dopamine_transporter_level').first
    @abstractor_subject_abstraction_schema_dat = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_dat.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id).first

    @abstractor_abstraction_schema_anatomical_location = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_anatomical_location').first
    @abstractor_subject_abstraction_schema_dat_anatomical_location = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_anatomical_location.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id).first

    @abstractor_abstraction_schema_recist_response = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_recist_response_criteria').first
    @abstractor_subject_abstraction_schema_recist_response = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_recist_response.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id).first
    @abstractor_subject_abstraction_schema_recist_anatomical_location = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_anatomical_location.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id).first

    @abstractor_abstraction_schema_diagnosis = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_diagnosis').first
    @abstractor_subject_abstraction_schema_diagnosis_1 = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_diagnosis.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id).first
    @abstractor_subject_abstraction_schema_diagnosis_2 = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_diagnosis.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id).first

    @abstractor_abstraction_schema_diagnosis_duration = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_diagnosis_duration').first
    @abstractor_subject_abstraction_schema_diagnosis_duration_1 = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_diagnosis_duration.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_1.id).first
    @abstractor_subject_abstraction_schema_diagnosis_duration_2 = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id: @abstractor_abstraction_schema_diagnosis_duration.id, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_imaging_exams_2.id).first

    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  before(:each) do
    @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  kps: 20.')
    @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
  end

  it "can report its abstractor subjects (namespaced)", focus: false do
    expect(Set.new(NoteStableIdentifier.abstractor_subjects(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id))).to eq Set.new([@abstractor_subject_abstraction_schema_dat, @abstractor_subject_abstraction_schema_dat_anatomical_location, @abstractor_subject_abstraction_schema_moomin_major, @abstractor_subject_abstraction_schema_diagnosis_1, @abstractor_subject_abstraction_schema_diagnosis_duration_1])
    expect(Set.new(NoteStableIdentifier.abstractor_subjects(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id))).to eq Set.new([@abstractor_subject_abstraction_schema_moomin_minor, @abstractor_subject_abstraction_schema_recist_response, @abstractor_subject_abstraction_schema_recist_anatomical_location, @abstractor_subject_abstraction_schema_diagnosis_2, @abstractor_subject_abstraction_schema_diagnosis_duration_2])
  end

  it "can report its abstractor abstraction schemas (namespaced)", focus: false do
    expect(Set.new(NoteStableIdentifier.abstractor_abstraction_schemas(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id))).to eq(Set.new([@abstractor_abstraction_schema_dat, @abstractor_abstraction_schema_anatomical_location,@abstractor_abstraction_schema_moomin_major, @abstractor_abstraction_schema_diagnosis, @abstractor_abstraction_schema_diagnosis_duration]))
    expect(Set.new(NoteStableIdentifier.abstractor_abstraction_schemas(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id))).to eq Set.new([@abstractor_abstraction_schema_moomin_minor, @abstractor_abstraction_schema_recist_response, @abstractor_abstraction_schema_anatomical_location, @abstractor_abstraction_schema_diagnosis, @abstractor_abstraction_schema_diagnosis_duration])
  end

  it "can report its abstractor subjects by schemas (namespaced)", focus: false do
    expect(
      Set.new(
        NoteStableIdentifier.abstractor_subjects(
          namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type,
          namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id,
          abstractor_abstraction_schema_ids: [
            @abstractor_abstraction_schema_recist_response.id,
            @abstractor_abstraction_schema_diagnosis.id,
            @abstractor_abstraction_schema_moomin_major.id
          ]
        )
      )
    ).to eq Set.new([@abstractor_subject_abstraction_schema_recist_response, @abstractor_subject_abstraction_schema_diagnosis_2])
  end

  describe "abstracting (namespaced)" do
    before(:each) do
      @abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'RECIST response criteria').first
      @note.note_text = 'The patient looks healthy.  Looks like a complete response to me.'
      @note.save!
      @note_stable_identifier.reload.abstract(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id: @abstractor_subject_abstraction_schema_recist_response.namespace_id)
    end

    #creating abstractions
    it "creates abstractions in the namespace", focus: false do
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_recist_response)).to_not be_nil
    end

    it "does not creates abstractions outside of the namespace", focus: false do
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_dat)).to be_nil
    end

    it "does not create another namespaced abstraction upon re-abstraction", focus: false do
      @note_stable_identifier.reload.abstract(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id: @abstractor_subject_abstraction_schema_recist_response.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions.select { |abstractor_abstraction| abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate == 'has_recist_response_criteria' }.size).to eq(1)
    end

    # creating groups
    it "creates a abstractor abstraction group in a namespace", focus: false do
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == @abstractor_subject_group }.size).to eq(1)
    end

    it "does not creates a abstractor abstraction group outside of a namespace", focus: false do
      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'Dopamine Transporter Level').first
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == abstractor_subject_group }.size).to eq(0)
    end

    it "does not create another abstractor abstraction group in a namespace upon re-abstraction", focus: false do
      @note_stable_identifier.reload.abstract
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == @abstractor_subject_group }.size).to eq(1)
    end

    it "creates an abstractor abstraction group member for each abstractor abstraction in a namespace", focus: false do
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == @abstractor_subject_group }.first.abstractor_abstractions.size).to eq(2)
    end

    it "does not create duplicate abstractor abstraction group members in a namespace upon re-abstraction", focus: false do
      @note_stable_identifier.reload.abstract
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == @abstractor_subject_group }.first.abstractor_abstractions.size).to eq(2)
    end

    it "creates an abstractor abstraction group member of the right kind for each abstractor abstraction in a namespace", focus: false do
      expect(Set.new(@note_stable_identifier.reload.abstractor_abstraction_groups.select { |abstractor_abstraction_group| abstractor_abstraction_group.abstractor_subject_group == @abstractor_subject_group }.first.abstractor_abstractions.map(&:abstractor_abstraction_schema))).to eq(Set.new([@abstractor_abstraction_schema_recist_response, @abstractor_abstraction_schema_anatomical_location]))
    end

    #reporting namespaced abstractions
    it 'can return abstractor abstractions in a namespace', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id).size).to eq(5)
    end

    it 'can return abstractor abstractions (regardless of namespace)', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace.size).to eq(10)
    end

    #reporting namespaced grouped abstractions
    it 'can return abstractor abstraction groups in a namespace', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id).size).to eq(2)
    end

    it 'can return abstractor abstraction groups (regardless of namespace)', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups_by_namespace.size).to eq(4)
    end

    it 'can return abstractor abstraction groups (regardless of namespace) but not excluding soft deleted rows', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      @note_stable_identifier.abstractor_abstraction_groups.first.soft_delete!
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups_by_namespace.size).to eq(3)
    end

    it 'can return abstractor abstraction groups (regardless of namespace) but not excluding soft deleted rows', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      @note_stable_identifier.abstractor_abstraction_groups.first.soft_delete!
      expect(@note_stable_identifier.reload.abstractor_abstraction_groups.size).to eq(4)
    end

    it 'can filter abstractor abstraction groups by subject group', focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      abstractor_subject_group = @note_stable_identifier.reload.abstractor_abstraction_groups_by_namespace.first.abstractor_subject_group
      expect(@note_stable_identifier.abstractor_abstraction_groups_by_namespace(abstractor_subject_group_id: abstractor_subject_group.id, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(1)
    end

    it "can report abstractions needing to be reviewed (regardless of namespace)", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW).size).to eq(10)
    end

    it "can report abstractions needing to be reviewed in a namespace", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW,namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(5)
    end

    it "can report what has been reviewed (regardless of namespace)", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      abstractor_suggestion = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_dat).abstractor_suggestions.first
      abstractor_suggestion.accepted = true
      abstractor_suggestion.save

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED).size).to eq(1)
    end

    it "can report what has been reviewed in a namespace", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      abstractor_suggestion = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_dat).abstractor_suggestions.first
      abstractor_suggestion.accepted = true
      abstractor_suggestion.save

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(1)
    end

    it "does not report what has been reviewed in another namespace", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      abstractor_suggestion = @note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_dat).abstractor_suggestions.first
      abstractor_suggestion.accepted = true
      abstractor_suggestion.save

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id).size).to eq(0)
    end

    #removing abstractions
    it "removes abstractions in a namespace", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(5)
      expect(@note_stable_identifier.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id).size).to eq(5)

      @note_stable_identifier.remove_abstractions(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(5)
      expect(@note_stable_identifier.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id).size).to eq(0)
    end

    it "will not remove reviewed abstractions in a namespace (if so instructed)", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      @note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(5)
      @note_stable_identifier.remove_abstractions(only_unreviewed: true, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).size).to eq(5)
    end

    #querying by abstractor abstraction status
    it "can report what needs to be reviewed in a namespace", focus: false do
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_recist_response.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_recist_response.namespace_id)).to eq([@note_stable_identifier])
    end

    it "only reports what needs to be reviewed in a namespace", focus: false do
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])
    end

    it "can report what needs to be reviewed in a namespace (ignoring soft deleted rows)", focus: false do
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty

      @note = FactoryGirl.create(:note, person: @person)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.soft_delete!
      end

      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty
    end

    it "can report what needs to be reviewed in a namespace (including 'blanked' values)", focus: false do
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty
      @note = FactoryGirl.create(:note, person: @person)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        expect(abstractor_abstraction.value).to be_nil
        abstractor_abstraction.value = ''
        abstractor_abstraction.save!
      end

      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])
    end

    it "can report what has been reviewed in a namespace (including 'blanked' values)", focus: false do
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty
      @note = FactoryGirl.create(:note, person: @person)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_NEEDS_REVIEW, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        expect(abstractor_abstraction.value).to be_nil
        abstractor_abstraction.value = ''
        abstractor_abstraction.save!
      end

      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty
    end

    it "can report what has been reviewed in a namespace", focus: false do
      @note = FactoryGirl.create(:note, person: @person)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])
    end

    it "can report what has been reviewed in a namespace (ignoring soft deleted rows)", focus: false do
      @note = FactoryGirl.create(:note, person: @person)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)
      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to eq([@note_stable_identifier])

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction.soft_delete!
      end

      expect(NoteStableIdentifier.by_abstractor_abstraction_status(Abstractor::Enum::ABSTRACTION_STATUS_REVIEWED, namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)).to be_empty
    end

    #pivoting groups
    it "can pivot grouped abstractions in a namespace as if regular columns on the abstractable entity", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name:'Dopamine Transporter Level').first
      abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: abstractor_subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)

      abstractor_subject_group.abstractor_subjects.each do |abstractor_subject|
        abstraction = abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
        abstractor_abstraction_group.abstractor_abstractions << abstraction
      end
      abstractor_abstraction_group.save!

      pivots = NoteStableIdentifier.pivot_grouped_abstractions('Dopamine Transporter Level', namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivots.each do |p|
        expect(p.respond_to?(:has_recist_response_criteria)).to be_falsey
      end
      pivots = pivots.map { |nsi| { id: nsi.id, stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, has_dopamine_transporter_level: nsi.has_dopamine_transporter_level, has_anatomical_location: nsi.has_anatomical_location } }
      expect(Set.new(pivots)).to eq(Set.new([{ id: @note_stable_identifier.id, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_dopamine_transporter_level: 'Normal', has_anatomical_location: 'parietal lobe' }, {id: @note_stable_identifier.id, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_dopamine_transporter_level: nil, has_anatomical_location: nil } ]))
    end

    it "can pivot grouped abstractions in a namepace as if regular columns on the abstractable entity if the value is marked as 'unknown'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.unknown = true
        abstractor_abstraction.save!
      end

      pivots = NoteStableIdentifier.pivot_grouped_abstractions('Dopamine Transporter Level', namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivots = pivots.map { |nsi| { id: nsi.id, stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, has_dopamine_transporter_level: nsi.has_dopamine_transporter_level, has_anatomical_location: nsi.has_anatomical_location } }
      expect(Set.new(pivots)).to eq(Set.new([{ id: @note_stable_identifier.id, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_dopamine_transporter_level: 'unknown', has_anatomical_location: 'unknown' } ]))
    end

    it "can pivot grouped abstractions in a namespace as if regular columns on the abstractable entity if the vaue is marked as 'not applicable'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.not_applicable = true
        abstractor_abstraction.save!
      end

      pivots = NoteStableIdentifier.pivot_grouped_abstractions('Dopamine Transporter Level', namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivots = pivots.map { |nsi| { id: nsi.id,  stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, has_dopamine_transporter_level: nsi.has_dopamine_transporter_level, has_anatomical_location: nsi.has_anatomical_location } }
      expect(Set.new(pivots)).to eq(Set.new([{ id: @note_stable_identifier.id,  stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_dopamine_transporter_level: 'not applicable', has_anatomical_location: 'not applicable' } ]))
    end

    #pivioting
    it "can pivot abstractions in a namespace as if regular columns on the abstractable entity", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.  Here favorite character is moominpapa.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = true
        abstractor_suggestion.save
      end

      pivot = NoteStableIdentifier.pivot_abstractions(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivot.each do |p|
        expect(p.respond_to?(:has_favorite_minor_moomin_character)).to be_falsey
      end

      pivot = pivot.map { |nsi| { id: nsi.id, note_text: nsi.note.note_text, stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, has_favorite_major_moomin_character: nsi.has_favorite_major_moomin_character } }
      expect(Set.new(pivot)).to eq(Set.new([{ id: @note_stable_identifier.id, note_text: @note_stable_identifier.note.note_text, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_favorite_major_moomin_character: 'moominpapa' } ]))
    end

    it "can pivot abstractions in a namespace as if regular columns on the abstractable entity if the value is marked as 'unknown'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.  Here favorite character is moominpapa.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.unknown = true
        abstractor_abstraction.save!
      end

      pivot = NoteStableIdentifier.pivot_abstractions(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivot = pivot.map { |nsi| { id: nsi.id, note_text: nsi.note.note_text, stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, note_date: nsi.note.note_date,  person_id: nsi.note.person_id, has_favorite_major_moomin_character: nsi.has_favorite_major_moomin_character } }
      expect(Set.new(pivot)).to eq(Set.new([{ id: @note_stable_identifier.id,  note_text: @note_stable_identifier.note.note_text, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, note_date: @note_stable_identifier.note.note_date, person_id: @note_stable_identifier.note.person_id, has_favorite_major_moomin_character: 'unknown' } ]))
    end

    it "can pivot abstractions in a namespace as if regular columns on the abstractable entity if the vaue is marked as 'not applicable'", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.  Here favorite character is moominpapa.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id)

      @note_stable_identifier.reload.abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_suggestion = abstractor_abstraction.abstractor_suggestions.first
        abstractor_suggestion.accepted = false
        abstractor_suggestion.save
        abstractor_abstraction.not_applicable = true
        abstractor_abstraction.save!
      end

      pivot = NoteStableIdentifier.pivot_abstractions(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivot = pivot.map { |nsi| { id: nsi.id,  note_text: nsi.note.note_text, person_id: nsi.note.person_id, note_date: nsi.note.note_date, stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, has_favorite_major_moomin_character: nsi.has_favorite_major_moomin_character } }
      expect(Set.new(pivot)).to eq(Set.new([{ id: @note_stable_identifier.id,  note_text: @note_stable_identifier.note.note_text, person_id: @note_stable_identifier.note.person_id, note_date: @note_stable_identifier.note.note_date, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_favorite_major_moomin_character: 'not applicable' } ]))
    end

    it "can pivot abstractions in a namespace as if regular columns on the abstractable entity (even if the entity has not been abstracted)", focus: false do
      @note = FactoryGirl.create(:note, person: @person, note_text: 'DaT scan: normal.  This is good news.  Very healthly looking parietal lobe.  Here favorite character is moominpapa.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')

      pivot = NoteStableIdentifier.pivot_abstractions(namespace_type: @abstractor_subject_abstraction_schema_dat.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_dat.namespace_id).where(id: @note_stable_identifier.id)
      pivot = pivot.map { |nsi| { id: nsi.id, note_text: nsi.note.note_text, person_id: nsi.note.person_id, note_date: nsi.note.note_date, stable_identifier_path: nsi.stable_identifier_path, stable_identifier_value: nsi.stable_identifier_value, has_favorite_major_moomin_character: nsi.has_favorite_major_moomin_character } }
      expect(Set.new(pivot)).to eq(Set.new([{ id: @note_stable_identifier.id,  note_text: @note_stable_identifier.note.note_text, person_id: @note_stable_identifier.note.person_id, note_date: @note_stable_identifier.note.note_date, stable_identifier_path: @note_stable_identifier.stable_identifier_path, stable_identifier_value: @note_stable_identifier.stable_identifier_value, has_favorite_major_moomin_character: nil } ]))
    end
  end

  describe "abstracting for specified schemas (namespaced)" do
    before(:each) do
      @abstractor_subject_group = Abstractor::AbstractorSubjectGroup.where(name: 'RECIST response criteria').first
      @note = FactoryGirl.create(:note, person: @person, note_text: 'The patient looks healthy.  Looks like a complete response to me.', note_date: Date.today)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note, stable_identifier_path: 'moomin character', stable_identifier_value: 'little my')
      @note_stable_identifier.abstract(
        namespace_type: @abstractor_subject_abstraction_schema_moomin_major.namespace_type,
        namespace_id:  @abstractor_subject_abstraction_schema_moomin_major.namespace_id,
        abstractor_abstraction_schema_ids: [
          @abstractor_abstraction_schema_moomin_major.id,
          @abstractor_abstraction_schema_dat.id,
          @abstractor_abstraction_schema_recist_response.id,
          @abstractor_abstraction_schema_diagnosis.id])
    end

    #creating abstractions
    it "creates selected abstractions in the namespace", focus: false do
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_moomin_major)).to_not be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_dat)).not_to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_diagnosis_1)).to_not be_nil

      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_dat_anatomical_location)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_diagnosis_duration_1)).to be_nil
    end


    it "does not create abstractions outside of the namespae", focus: false do
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_moomin_minor)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_recist_response)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_recist_anatomical_location)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_diagnosis_2)).to be_nil
      expect(@note_stable_identifier.reload.detect_abstractor_abstraction(@abstractor_subject_abstraction_schema_diagnosis_duration_2)).to be_nil
    end

    #removing abstractions
    it "removes abstractions in a namespace", focus: false do
      @note_stable_identifier.abstract(namespace_type: @abstractor_subject_abstraction_schema_moomin_minor.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_moomin_minor.namespace_id)

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_moomin_minor.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_moomin_minor.namespace_id).size).to eq(5)
      expect(@note_stable_identifier.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_moomin_major.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_moomin_major.namespace_id).size).to eq(3)

      @note_stable_identifier.remove_abstractions(
        namespace_type: @abstractor_subject_abstraction_schema_moomin_major.namespace_type,
        namespace_id:  @abstractor_subject_abstraction_schema_moomin_major.namespace_id,
        abstractor_abstraction_schema_ids: [@abstractor_subject_abstraction_schema_moomin_minor.id, @abstractor_abstraction_schema_moomin_major.id, @abstractor_abstraction_schema_diagnosis.id])

      expect(@note_stable_identifier.reload.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_moomin_minor.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_moomin_minor.namespace_id).size).to eq(5)
      expect(@note_stable_identifier.abstractor_abstractions_by_namespace(namespace_type: @abstractor_subject_abstraction_schema_moomin_major.namespace_type, namespace_id:  @abstractor_subject_abstraction_schema_moomin_major.namespace_id).size).to eq(1)
    end
  end
end