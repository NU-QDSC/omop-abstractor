require 'rails_helper'
describe Abstractor::AbstractorAbstractionGroup do
  let!(:abstractor_subject_group) { FactoryGirl.create(:abstractor_subject_group) }

  before(:each) do
    ENV['PGPASSWORD'] = Rails.configuration.database_configuration[Rails.env]['password']
    `psql -h #{Rails.configuration.database_configuration[Rails.env]['host']} --u #{Rails.configuration.database_configuration[Rails.env]['username']} -d #{Rails.configuration.database_configuration[Rails.env]['database']} -f "#{Rails.root}/db/migrate/CommonDataModel-5.3.0/PostgreSQL/DROP OMOP CDM postgresql constraints.sql"`

    Abstractor::Setup.system
    list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first

    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
    @note = FactoryGirl.create(:note, person: @person)
    @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)

    @abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.create!(predicate: 'has_falls', display_name: 'Falls',  abstractor_object_type: list_object_type)
    @subject_group = abstractor_subject_group
    @abstractor_subject = Abstractor::AbstractorSubject.create(subject_type: 'Note', abstractor_abstraction_schema: @abstractor_abstraction_schema)
    Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: @abstractor_subject, abstractor_subject_group: @subject_group, display_order: 1)
    @abstraction = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    @abstraction.save!
  end

  it "is not valid if AbstractorSubjectGroup does not have members", focus: false do
    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: abstractor_subject_group.id)
    expect(abstractor_abstraction_group).not_to be_valid
    expect(abstractor_abstraction_group.errors.full_messages).to include 'Must have at least one abstractor_abstraction_group_member'
  end

  it "knows if it has a 'discarded' workflow_status", focus: false do
    abstraction_1 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    abstraction_1.save!

    abstraction_2 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    abstraction_2.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstraction_1
    abstractor_abstraction_group.abstractor_abstractions << abstraction_2
    abstractor_abstraction_group.save!

    abstraction_1.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
    abstraction_1.save!

    expect(abstractor_abstraction_group.discarded?).to be_falsey

    abstraction_2.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
    abstraction_2.save!
    expect(abstractor_abstraction_group.discarded?).to be_truthy
  end

  it "knows if it has a 'submitted' workflow_status", focus: false do
    abstraction_1 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    abstraction_1.save!
    puts 'hello'
    puts abstraction_1.abstractor_subject.abstractor_abstraction_schema.id

    abstraction_2 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    abstraction_2.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstraction_1
    abstractor_abstraction_group.abstractor_abstractions << abstraction_2
    abstractor_abstraction_group.save!

    abstraction_1.value = 'moomin'
    abstraction_1.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
    abstraction_1.save!

    expect(abstractor_abstraction_group.submitted?).to be_falsey

    abstraction_2.value = 'moomin'
    abstraction_2.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
    abstraction_2.save!
    expect(abstractor_abstraction_group.submitted?).to be_truthy
  end

  it "knows if it is 'fully set'", focus: false do
    abstraction_1 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    abstraction_1.save!

    abstraction_2 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s)
    abstraction_2.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstraction_1
    abstractor_abstraction_group.abstractor_abstractions << abstraction_2
    abstractor_abstraction_group.save!

    abstraction_1.value = 'moomin'
    abstraction_1.save!

    expect(abstractor_abstraction_group.fully_set?).to be_falsey

    abstraction_2.value = 'moomin'
    abstraction_2.save!

    expect(abstractor_abstraction_group.fully_set?).to be_truthy
  end

  it "knows its workflow_status", focus: false do
    abstraction_1 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s, workflow_status: Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
    abstraction_1.save!

    abstraction_2 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s, workflow_status: Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
    abstraction_2.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstraction_1
    abstractor_abstraction_group.abstractor_abstractions << abstraction_2
    abstractor_abstraction_group.save!

    abstraction_1.value = 'moomin'
    abstraction_1.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
    abstraction_1.save!

    expect(abstractor_abstraction_group.workflow_status).to match_array(['pending','submitted'])

    abstraction_2.value = 'moomin'
    abstraction_2.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
    abstraction_2.save!
    expect(abstractor_abstraction_group.workflow_status).to match_array(['submitted'])
  end

  it "knows it is 'read only'", focus: false do
    abstraction_1 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s, workflow_status: Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
    abstraction_1.save!

    abstraction_2 = @abstractor_subject.abstractor_abstractions.build(about_id: @note_stable_identifier.id, about_type: NoteStableIdentifier.to_s, workflow_status: Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
    abstraction_2.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstraction_1
    abstractor_abstraction_group.abstractor_abstractions << abstraction_2
    abstractor_abstraction_group.save!

    expect(abstractor_abstraction_group.read_only?).to be_falsey

    abstraction_2.value = 'moomin'
    abstraction_2.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
    abstraction_2.save!
    expect(abstractor_abstraction_group.read_only?).to be_truthy
  end

  # it "knows if it does not have a 'discarded' workflow_status", focus: false do
  #   expect(@abstractor_abstraction.discarded?).to be_falsey
  # end

  # it "is not valid if members belong to different namespaces" do
  #   abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: 1)
  #   abstractor_abstraction_group.abstractor_abstractions << @abstraction
  #   expect(abstractor_abstraction_group).to be_valid

  #   abstractor_subject_1 = Abstractor::AbstractorSubject.create(subject_type: 'ImagingExam', abstractor_abstraction_schema: @abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
  #   Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: abstractor_subject_1, abstractor_subject_group: @subject_group, display_order: 1)
  #   abstraction_1 = abstractor_subject_1.abstractor_abstractions.build(about_id: 1, about_type: NoteStableIdentifier.to_s)
  #   abstraction_1.save!

  #   abstractor_abstraction_group.abstractor_abstractions << abstraction_1
  #   expect(abstractor_abstraction_group).not_to be_valid
  #   expect(abstractor_abstraction_group.errors.full_messages).to include 'Must have same namespace for all abstractor_abstraction_group_members'
  # end

  # it "is valid if members belong to the same namespace" do
  #   abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: 1)
  #   abstractor_abstraction_group.abstractor_abstractions << @abstraction
  #   expect(abstractor_abstraction_group).to be_valid

  #   abstractor_subject_1 = Abstractor::AbstractorSubject.create(subject_type: 'ImagingExam', abstractor_abstraction_schema: @abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
  #   Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: abstractor_subject_1, abstractor_subject_group: @subject_group, display_order: 1)
  #   abstraction_1 = abstractor_subject_1.abstractor_abstractions.build(about_id: 1, about_type: NoteStableIdentifier.to_s)
  #   abstraction_1.save!

  #   abstractor_abstraction_group.abstractor_abstractions << @abstraction
  #   expect(abstractor_abstraction_group).to be_valid
  # end

  it "is valid if parent AbstractorSubjectGroup cardinality is not defined", focus: false do
    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    expect(abstractor_abstraction_group).to be_valid
    abstractor_abstraction_group.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    expect(abstractor_abstraction_group).to be_valid
  end

  it "is valid if maximum number of groups for parent AbstractorSubjectGroup is not reached", focus: false do
    @subject_group.cardinality = 1
    @subject_group.save

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    expect(abstractor_abstraction_group).to be_valid
  end

  it "is not valid if maximum number of groups for parent AbstractorSubjectGroup is reached", focus: false do
    @subject_group.cardinality = 1
    @subject_group.save

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    abstractor_abstraction_group.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    expect(abstractor_abstraction_group).not_to be_valid
    expect(abstractor_abstraction_group.errors.full_messages).to include 'Subject group reached maximum number of abstraction groups (1)'
  end

  it "is does not count deleted abstraction_groups", focus: false do
    @subject_group.cardinality = 1
    @subject_group.save

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    abstractor_abstraction_group.save!
    abstractor_abstraction_group.soft_delete!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << @abstraction
    expect(abstractor_abstraction_group).to be_valid
  end

  # it "if cardinality is defined and grouped abstractions are namespaced, it checks cardinality against each namespace" do
  #   @subject_group.cardinality = 1
  #   @subject_group.save

  #   abstractor_subject_1 = Abstractor::AbstractorSubject.create(subject_type: 'ImagingExam', abstractor_abstraction_schema: @abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
  #   Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: abstractor_subject_1, abstractor_subject_group: @subject_group, display_order: 1)
  #   abstraction_1 = abstractor_subject_1.abstractor_abstractions.build(about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
  #   abstraction_1.save!

  #   abstractor_subject_2 = Abstractor::AbstractorSubject.create(subject_type: 'ImagingExam', abstractor_abstraction_schema: @abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2)
  #   Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: abstractor_subject_2, abstractor_subject_group: @subject_group, display_order: 1)
  #   abstraction_2 = abstractor_subject_2.abstractor_abstractions.build(about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
  #   abstraction_2.save!

  #   @subject_group.reload.abstractor_subjects.each do |abstractor_subject|
  #     abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
  #     abstractor_abstraction_group.abstractor_abstractions << abstractor_subject.abstractor_abstractions.first
  #     expect(abstractor_abstraction_group).to be_valid
  #     abstractor_abstraction_group.save!

  #     abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
  #     abstractor_abstraction_group.abstractor_abstractions << abstractor_subject.abstractor_abstractions.first
  #     expect(abstractor_abstraction_group).not_to be_valid
  #   end
  # end

  it "if cardinality is defined and grouped abstractions are namespaced, it checks cardinality against each about", focus: false do
    @subject_group.cardinality = 1
    @subject_group.save

    abstractor_subject_1 = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 1)
    Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: abstractor_subject_1, abstractor_subject_group: @subject_group, display_order: 1)
    abstraction_1 = abstractor_subject_1.abstractor_abstractions.build(about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstraction_1.save!

    abstractor_subject_2 = Abstractor::AbstractorSubject.create(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: @abstractor_abstraction_schema, namespace_type: 'Discerner::Search', namespace_id: 2)
    Abstractor::AbstractorSubjectGroupMember.create(abstractor_subject: abstractor_subject_2, abstractor_subject_group: @subject_group, display_order: 1)
    abstraction_2 = abstractor_subject_2.abstractor_abstractions.build(about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstraction_2.save!


    note_2 = FactoryGirl.create(:note, person: @person)
    note_stable_identifier_2 = FactoryGirl.create(:note_stable_identifier, note: note_2)

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstractor_subject_1.abstractor_abstractions.first
    expect(abstractor_abstraction_group).to be_valid
    abstractor_abstraction_group.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: @note_stable_identifier.id)
    abstractor_abstraction_group.abstractor_abstractions << abstractor_subject_1.abstractor_abstractions.first
    expect(abstractor_abstraction_group).not_to be_valid

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: note_stable_identifier_2.id)
    abstractor_abstraction_group.abstractor_abstractions << abstractor_subject_2.abstractor_abstractions.first
    expect(abstractor_abstraction_group).to be_valid
    abstractor_abstraction_group.save!

    abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: @subject_group.id, about_type: NoteStableIdentifier.to_s, about_id: note_stable_identifier_2.id)
    abstractor_abstraction_group.abstractor_abstractions << abstractor_subject_2.abstractor_abstractions.first
    expect(abstractor_abstraction_group).not_to be_valid
  end
end