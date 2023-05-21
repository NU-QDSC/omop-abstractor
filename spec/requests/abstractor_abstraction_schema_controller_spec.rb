require 'rails_helper'
describe AbstractorAbstractionSchemasController, :type => :request do
  let(:accept_json) { { "Accept" => "application/json" } }
  let(:json_content_type) { { "Content-Type" => "application/json" } }
  let(:accept_and_return_json) { accept_json.merge(json_content_type) }

  before(:each) do
    Abstractor::Setup.system
    AbstractorAbstractionSchemasController.any_instance.stub(:authenticate_user!).and_return(true)
  end

  describe "GET /abstractor_abstraction_schemas/:id" do
    it "returns an abstraction schema", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      abstractor_abstraction_schema = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property')
      abstractor_abstraction_schema.abstractor_abstraction_schema_predicate_variants << FactoryGirl.build(:abstractor_abstraction_schema_predicate_variant, value: 'smoperty')
      abstractor_abstraction_schema.abstractor_object_values << FactoryGirl.build(:abstractor_object_value, value: 'foo', properties: '{  "type":"Rpt", "select_for":"Brain, CNS, and Pituitary" }', vocabulary_code: '8148/0', vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3', case_sensitive: true)
      FactoryGirl.create(:abstractor_object_value_variant, abstractor_object_value: abstractor_abstraction_schema.abstractor_object_values.first, value: 'boo', case_sensitive: true)

      get "/abstractor_abstraction_schemas/#{abstractor_abstraction_schema.id}", params: {}, headers: headers

      expect(response.status).to eq(200)

      body = JSON.parse(response.body)
      expect(body['abstractor_abstraction_schema']['predicate']).to eq 'has_some_property'
      expect(body['abstractor_abstraction_schema']['display_name']).to eq 'some_property'
      expect(body['abstractor_abstraction_schema']['abstractor_object_type']).to eq 'list'
      expect(body['abstractor_abstraction_schema']['preferred_name']).to eq 'property'
      expect(body['abstractor_abstraction_schema']['predicate_variants']).to eq  [{ 'value' => 'smoperty' }]
      expect(body['abstractor_abstraction_schema']['object_values']).to eq  [{"value"=>"foo", "properties" => {"type"=>"Rpt", "select_for"=>"Brain, CNS, and Pituitary"}, "vocabulary_code"=>"8148/0", "vocabulary"=>"ICD-O-3", "vocabulary_version"=>"2011 Updates to ICD-O-3", "case_sensitive"=> "true", "object_value_variants"=>[{"value"=>"boo", "case_sensitive"=> "true"}]}]
    end

    it 'returns an abstraction schema (but not soft deleted object values and soft deleted object value variants)', focus: false do

      headers = { "Accept" => "application/json" }
      abstractor_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      abstractor_abstraction_schema = FactoryGirl.create(:abstractor_abstraction_schema, predicate: 'has_some_property', display_name: 'some_property', abstractor_object_type: abstractor_object_type, preferred_name: 'property')
      abstractor_abstraction_schema.abstractor_abstraction_schema_predicate_variants << FactoryGirl.build(:abstractor_abstraction_schema_predicate_variant, value: 'smoperty')
      abstractor_object_value_1 = FactoryGirl.build(:abstractor_object_value, value: 'foo', properties: '{  "type":"Rpt", "select_for":"Brain, CNS, and Pituitary" }', vocabulary_code: '8148/0', vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3', case_sensitive: false)
      abstractor_abstraction_schema.abstractor_object_values << abstractor_object_value_1
      abstractor_object_value_2 = FactoryGirl.build(:abstractor_object_value, value: 'loo', properties: '{  "type":"Rpt", "select_for":"Brain, CNS, and Pituitary" }', vocabulary_code: '8149/0', vocabulary: 'ICD-O-3', vocabulary_version: '2011 Updates to ICD-O-3', case_sensitive: false)
      abstractor_abstraction_schema.abstractor_object_values << abstractor_object_value_2
      abstractor_object_value_variant = FactoryGirl.create(:abstractor_object_value_variant, abstractor_object_value: abstractor_abstraction_schema.abstractor_object_values.first, value: 'boo', case_sensitive: true)

      get "/abstractor_abstraction_schemas/#{abstractor_abstraction_schema.id}", params: {}, headers: headers
      expect(response.status).to be 200
      body = JSON.parse(response.body)

      expect(body['abstractor_abstraction_schema']['object_values']).to match_array([{"value"=>"foo", "properties" => {"type"=>"Rpt", "select_for"=>"Brain, CNS, and Pituitary"}, "vocabulary_code"=>"8148/0", "vocabulary"=>"ICD-O-3", "vocabulary_version"=>"2011 Updates to ICD-O-3", "case_sensitive"=> "false", "object_value_variants"=>[{"value"=>"boo", "case_sensitive"=> "true"}]}, {"value"=>"loo", "properties"=>{"type"=>"Rpt", "select_for"=>"Brain, CNS, and Pituitary"}, "vocabulary_code"=>"8149/0", "vocabulary"=>"ICD-O-3", "vocabulary_version"=>"2011 Updates to ICD-O-3", "case_sensitive"=>"false", "object_value_variants"=>[]}])
      abstractor_object_value_2.soft_delete!
      abstractor_object_value_variant.soft_delete!
      get "/abstractor_abstraction_schemas/#{abstractor_abstraction_schema.id}", params: {}, headers: headers
      body = JSON.parse(response.body)
      expect(body['abstractor_abstraction_schema']['object_values']).to eq  [{"value"=>"foo", "properties" => {"type"=>"Rpt", "select_for"=>"Brain, CNS, and Pituitary"}, "vocabulary_code"=>"8148/0", "vocabulary"=>"ICD-O-3", "vocabulary_version"=>"2011 Updates to ICD-O-3", "case_sensitive"=>"false", "object_value_variants"=>[]}]
    end
  end
end