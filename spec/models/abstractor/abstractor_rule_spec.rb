require 'rails_helper'
describe  Abstractor::AbstractorAbstraction do
  before(:each) do
    Abstractor::Setup.system
    abstractor_object_type = Abstractor::AbstractorObjectType.first
    abstractor_rule_type = Abstractor::AbstractorRuleType.first

    abstractor_abstraction_schema_1 = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property')
    @abstractor_subject_1 = FactoryGirl.build(:abstractor_subject, subject_type: 'Foo')
    abstractor_abstraction_schema_1.abstractor_subjects << @abstractor_subject_1

    abstractor_abstraction_schema_2 = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property_2', display_name: 'some_property_2', abstractor_object_type: abstractor_object_type, preferred_name: 'property_2')
    @abstractor_subject_2 = FactoryGirl.build(:abstractor_subject, subject_type: 'Foo')
    abstractor_abstraction_schema_2.abstractor_subjects << @abstractor_subject_2

    abstractor_abstraction_schema_3 = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property_3', display_name: 'some_property_3', abstractor_object_type: abstractor_object_type, preferred_name: 'property_3')
    @abstractor_subject_3 = FactoryGirl.build(:abstractor_subject, subject_type: 'Foo')
    abstractor_abstraction_schema_3.abstractor_subjects << @abstractor_subject_3

    abstractor_abstraction_schema_4 = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property_4', display_name: 'some_property_4', abstractor_object_type: abstractor_object_type, preferred_name: 'property_4')
    @abstractor_subject_4 = FactoryGirl.build(:abstractor_subject, subject_type: 'Foo')
    abstractor_abstraction_schema_4.abstractor_subjects << @abstractor_subject_4

    @abstractor_rule_1 = FactoryGirl.create(:abstractor_rule, rule: 'foo rule')
    @abstractor_rule_1.abstractor_rule_abstractor_subjects.build(abstractor_subject: @abstractor_subject_1)
    @abstractor_rule_1.abstractor_rule_abstractor_subjects.build(abstractor_subject: @abstractor_subject_2)
    @abstractor_rule_1.save!

    @abstractor_rule_2 = FactoryGirl.create(:abstractor_rule, rule: 'foo rule 2')
    @abstractor_rule_2.abstractor_rule_abstractor_subjects.build(abstractor_subject: @abstractor_subject_3)
    @abstractor_rule_2.abstractor_rule_abstractor_subjects.build(abstractor_subject: @abstractor_subject_4)
    @abstractor_rule_2.save!
  end

  it 'can search for abstractor rules by abstractor subject', focus: false do
    expect(Abstractor::AbstractorRule.search_by_abstractor_subjects_ids([@abstractor_subject_1.id, @abstractor_subject_2.id])).to match_array([@abstractor_rule_1])
  end
end