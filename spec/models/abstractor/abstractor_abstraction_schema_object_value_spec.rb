require 'rails_helper'
describe Abstractor::AbstractorAbstractionSchemaObjectValue do
  before(:each) do
    Abstractor::Setup.system
  end

  let(:abstractor_object_type)        { Abstractor::AbstractorObjectType.all.sample }
  let(:abstractor_object_value)       { FactoryGirl.create(:abstractor_object_value, value: 'foo') }
  let(:abstractor_abstraction_schema) { FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property') }

  it 'updates datestamp on abstractor_abstraction_schema on create', focus: false do
    timestamp = abstractor_abstraction_schema.updated_at
    Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value)
    expect(abstractor_abstraction_schema.reload.updated_at).to be > timestamp
  end

  it 'updates datestamp on abstractor_abstraction_schema on update', focus: false do
    abstractor_abstraction_schema_object_value = Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value)
    timestamp = abstractor_abstraction_schema.updated_at
    abstractor_abstraction_schema_object_value.display_order = 10
    abstractor_abstraction_schema_object_value.save!
    expect(abstractor_abstraction_schema.reload.updated_at).to be > timestamp
  end

  it 'updates datestamp on abstractor_abstraction_schema on destroy', focus: false do
    abstractor_abstraction_schema_object_value = Abstractor::AbstractorAbstractionSchemaObjectValue.create(abstractor_abstraction_schema: abstractor_abstraction_schema, abstractor_object_value: abstractor_object_value)
    timestamp = abstractor_abstraction_schema.updated_at
    abstractor_abstraction_schema_object_value.destroy
    expect(abstractor_abstraction_schema.reload.updated_at).to be > timestamp
  end
end