require 'rails_helper'
describe  Abstractor::AbstractorAbstraction do
 before(:each) do
   Abstractor::Setup.system
   abstractor_object_type = Abstractor::AbstractorObjectType.first
   abstractor_rule_type = Abstractor::AbstractorRuleType.first
   abstractor_abstraction_source_type = Abstractor::AbstractorAbstractionSourceType.first
   abstractor_abstraction_schema = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property')

   @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
   @no_matching_concept = FactoryGirl.create(:no_matching_concept)
   @undefined_concept = FactoryGirl.create(:undefined_concept)
   @person = FactoryGirl.create(:person)
   @note = FactoryGirl.create(:note, person: @person, note_text: 'Little my says hi!')
   @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)

   @abstractor_subject = FactoryGirl.create(:abstractor_subject, subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema: abstractor_abstraction_schema)
   @abstractor_abstraction = FactoryGirl.create(:abstractor_abstraction, abstractor_subject: @abstractor_subject, about: @note_stable_identifier, unknown: nil)
   @abstractor_abstraction_2 = FactoryGirl.create(:abstractor_abstraction, abstractor_subject: @abstractor_subject, about: @note_stable_identifier, unknown: nil)
   @abstractor_abstraction_3 = FactoryGirl.create(:abstractor_abstraction, abstractor_subject: @abstractor_subject, about: @note_stable_identifier, unknown: nil)

   @abstractor_suggestion_bar = FactoryGirl.create(:abstractor_suggestion, abstractor_abstraction: @abstractor_abstraction, accepted: nil, suggested_value: 'bar')
   @abstractor_suggestion_boo = FactoryGirl.create(:abstractor_suggestion, abstractor_abstraction: @abstractor_abstraction, accepted: nil, suggested_value: 'boo')
   @abstractor_suggestion_foo = FactoryGirl.create(:abstractor_suggestion, abstractor_abstraction: @abstractor_abstraction, accepted: false , suggested_value: 'foo')
   @from_method = 'note_text'
   @abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create!(abstractor_subject: @abstractor_subject, from_method: @from_method, abstractor_abstraction_source_type: abstractor_abstraction_source_type, abstractor_rule_type: abstractor_rule_type)

   FactoryGirl.create(:abstractor_suggestion_source, abstractor_suggestion: @abstractor_suggestion_foo, abstractor_abstraction_source: @abstractor_abstraction_source)
 end

 it "can detect a suggestion from a suggested value", focus: false do
   expect(@abstractor_abstraction.detect_abstractor_suggestion('bar', nil, nil)).to eq(@abstractor_suggestion_bar)
 end

 it "knows if an abstraction is unreviewed", focus: false do
   expect(@abstractor_abstraction.unreviewed?).to be_truthy
 end

 it "can report unreviewd suggestions", focus: false do
   expect(@abstractor_abstraction.reload.unreviewed_abstractor_suggestions).to eq([@abstractor_suggestion_bar, @abstractor_suggestion_boo])
 end

 it 'can remove unreviewed suggestions not matching suggestions', focus: false do
   @abstractor_abstraction.reload.remove_unreviewed_suggestions_not_matching_suggestions([{suggestion: 'bar', explanation: 'Here is the deal.' }])
   expect(@abstractor_abstraction.reload.abstractor_suggestions).to eq([@abstractor_suggestion_bar, @abstractor_suggestion_foo])
 end

 it "knows if an abstraction is not unreviewed", focus: false do
   @abstractor_suggestion_bar.accepted = true
   @abstractor_suggestion_bar.save!
   expect(@abstractor_abstraction.reload.unreviewed?).to be_falsey
 end

 it "can detect an indirect source", focus: false do
   @abstractor_abstraction.abstractor_indirect_sources.build(abstractor_abstraction_source: @abstractor_abstraction_source)
   @abstractor_abstraction.save!
   expect(@abstractor_abstraction.reload.detect_abstractor_indirect_source(@abstractor_abstraction_source)).to_not be_nil
 end

 it 'clears itself of a value', focus: false do
   @abstractor_abstraction.value = 'moomin'
   @abstractor_abstraction.clear
   expect(@abstractor_abstraction.value).to eq(nil)
 end

 it 'clears itself of an unknown value', focus: false do
   @abstractor_abstraction.unknown = true
   @abstractor_abstraction.clear
   expect(@abstractor_abstraction.unknown).to eq(nil)
 end

 it 'clears itself of a not applicable value', focus: false do
   @abstractor_abstraction.not_applicable = true
   @abstractor_abstraction.clear
   expect(@abstractor_abstraction.not_applicable).to eq(nil)
 end

 it 'clears itself of a value and saves', focus: false do
   @abstractor_abstraction.value = 'moomin'
   @abstractor_abstraction.clear!
   expect(@abstractor_abstraction.reload.value).to eq(nil)
 end

 it 'clears itself of an unknown value and saves', focus: false do
   @abstractor_abstraction.unknown = true
   @abstractor_abstraction.clear
   expect(@abstractor_abstraction.reload.unknown).to eq(nil)
 end

 it 'clears itself of a not applicable value and saves', focus: false do
   @abstractor_abstraction.not_applicable = true
   @abstractor_abstraction.clear
   expect(@abstractor_abstraction.reload.not_applicable).to eq(nil)
 end

 it "knows if it has a 'submitted' workflow_status", focus: false do
   @abstractor_abstraction.value = 'moomin'
   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
   @abstractor_abstraction.save!
   expect(@abstractor_abstraction.submitted?).to be_truthy
 end

 it 'clears itself of a value and saves and destroys a user-contributed suggestion', focus: false do
   @abstractor_suggestion_boo.accepted = true
   @abstractor_suggestion_boo.save!
   expect(@abstractor_abstraction.reload.value).to eq('boo')
   @abstractor_abstraction.clear!
   expect(@abstractor_abstraction.reload.value).to eq(nil)
   expect(Abstractor::AbstractorSuggestion.where(id: @abstractor_suggestion_boo.id).first).to eq(nil)
 end

 it 'clears itself of a value and saves and sets to not accepted suggestions with sources', focus: false do
   @abstractor_suggestion_foo.accepted = true
   @abstractor_suggestion_foo.save!
   expect(@abstractor_abstraction.reload.value).to eq('foo')
   @abstractor_abstraction.clear!
   expect(@abstractor_abstraction.reload.value).to eq(nil)
   expect(@abstractor_suggestion_foo.reload.accepted).to be_nil
 end

 it "knows if it does not have a 'submitted' workflow_status", focus: false do
   expect(@abstractor_abstraction.submitted?).to be_falsey
 end

 it "knows if it has a 'discarded' workflow_status", focus: false do
   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
   @abstractor_abstraction.save!
   expect(@abstractor_abstraction.discarded?).to be_truthy
 end

 it "knows if it does not have a 'discarded' workflow_status", focus: false do
   expect(@abstractor_abstraction.discarded?).to be_falsey
 end

 it 'updates the workflow status of abstractions', focus: false do
   @abstractor_abstraction.value = 'moomin'
   @abstractor_abstraction_2.value = 'moomin'
   @abstractor_abstraction_3.value = 'moomin'
   expect(@abstractor_abstraction.workflow_status).to be_nil
   expect(@abstractor_abstraction_2.workflow_status).to be_nil
   expect(@abstractor_abstraction_3.workflow_status).to be_nil
   Abstractor::AbstractorAbstraction.update_abstractor_abstraction_workflow_status([@abstractor_abstraction, @abstractor_abstraction_2], Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED, 'moomin')
   expect(@abstractor_abstraction.reload.workflow_status).to eq(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED)
   expect(@abstractor_abstraction_2.reload.workflow_status).to eq(Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED)
   expect(@abstractor_abstraction_3.reload.workflow_status).to be_nil
   expect(@abstractor_abstraction.reload.workflow_status_whodunnit).to eq('moomin')
   expect(@abstractor_abstraction_2.reload.workflow_status_whodunnit).to eq('moomin')
   expect(@abstractor_abstraction_3.reload.workflow_status_whodunnit).to be_nil
 end

 it "validates if it is blank and has a workflowstatus of submitted", focus: false do
   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
   @abstractor_abstraction.valid?
   expect(@abstractor_abstraction.errors.full_messages).to match_array(["Workflow status can't have a workflow status of submitted and be blank."])
 end

 it "validates if it is blank and has a workflowstatus of pending", focus: false do
   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING
   @abstractor_abstraction.valid?
   expect(@abstractor_abstraction.errors.full_messages).to be_empty
 end

 it "validates if it is blank and has a workflowstatus of discarded", focus: false do
   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_DISCARDED
   @abstractor_abstraction.valid?
   expect(@abstractor_abstraction.errors.full_messages).to be_empty
 end

 it "validates if it is not blank and has a workflowstatus of submitted", focus: false do
   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
   @abstractor_abstraction.value = 'moomin'
   @abstractor_abstraction.valid?
   expect(@abstractor_abstraction.errors.full_messages).to be_empty

   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
   @abstractor_abstraction.value = nil
   @abstractor_abstraction.unknown = true
   @abstractor_abstraction.not_applicable = nil
   @abstractor_abstraction.valid?
   expect(@abstractor_abstraction.errors.full_messages).to be_empty

   @abstractor_abstraction.workflow_status = Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_SUBMITTED
   @abstractor_abstraction.value = nil
   @abstractor_abstraction.unknown = nil
   @abstractor_abstraction.not_applicable = false
   @abstractor_abstraction.valid?
   expect(@abstractor_abstraction.errors.full_messages).to be_empty
 end
end
