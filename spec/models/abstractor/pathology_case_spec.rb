require 'rails_helper'
describe NoteStableIdentifier do
  before(:each) do
    Abstractor::Setup.system
    list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
    custom_nlp_suggestion_source_type = Abstractor::AbstractorAbstractionSourceType.where(name: 'custom nlp suggestion').first
    abstractor_rule_type_value = Abstractor::AbstractorRuleType.where(name: Abstractor::Enum::ABSTRACTOR_RULE_TYPE_VALUE).first

    @abstractor_abstraction_schema_has_cancer_histology = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_histology',
      display_name: 'Cancer Histology',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    histologies =  [{ name: 'carcinoma in situ, nos', icdo3_code: '8010/2' }, { name: 'carcinoma, nos', icdo3_code: '8010/3' }, { name: 'carcinoma, metastatic, nos', icdo3_code: '8010/6' }]
    histologies.each do |histology|
      abstractor_object_value = Abstractor::AbstractorObjectValue.create(:value => "#{histology[:name]} (#{histology[:icdo3_code]})")
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: @abstractor_abstraction_schema_has_cancer_histology, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.create(:abstractor_object_value => abstractor_object_value, :value => histology[:name])
      histology_synonyms = [{ synonym_name: 'intraepithelial carcinoma, nos', icdo3_code: '8010/2' }, { synonym_name: 'carcinoma in situ', icdo3_code: '8010/2' }, { synonym_name: 'intraepithelial carcinoma', icdo3_code: '8010/2' }, { synonym_name: 'carcinoma', icdo3_code: '8010/3' }, { synonym_name: 'malignant epithelial tumor', icdo3_code: '8010/3' }, { synonym_name: 'epithelial tumor malignant', icdo3_code: '8010/3' }, { synonym_name: 'secondary carcinoma', icdo3_code: '8010/6' }, { synonym_name: 'metastatic carcinoma', icdo3_code: '8010/6' }, { synonym_name: 'carcinoma metastatic', icdo3_code: '8010/6' }]
      histology_synonyms.select { |histology_synonym| histology.to_hash[:icdo3_code] == histology_synonym.to_hash[:icdo3_code] }.each do |histology_synonym|
        Abstractor::AbstractorObjectValueVariant.create(:abstractor_object_value => abstractor_object_value, :value => histology_synonym[:synonym_name])
      end
    end

    @abstractor_namespace_pathology_cases = Abstractor::AbstractorNamespace.where(name: 'Pathology Cases', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create
    @abstractor_subject_abstraction_schema_has_cancer_histology = Abstractor::AbstractorSubject.create(:subject_type => NoteStableIdentifier.to_s, :abstractor_abstraction_schema => @abstractor_abstraction_schema_has_cancer_histology, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_pathology_cases.id)
    @abstractor_abstraction_source_has_cancer_histology = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_abstraction_schema_has_cancer_histology, from_method: 'note_text', abstractor_abstraction_source_type: custom_nlp_suggestion_source_type, custom_nlp_provider:  'custom_nlp_provider_name', abstractor_rule_type: abstractor_rule_type_value)

    @abstractor_abstraction_schema_has_cancer_site = Abstractor::AbstractorAbstractionSchema.where(
      predicate: 'has_cancer_site',
      display_name: 'Cancer Site',
      abstractor_object_type: list_object_type,
      preferred_name: 'cancer histology').first_or_create

    sites =  [{ name: 'heart', icdo3_code: 'C38.0' }, { name: 'main bronchus', icdo3_code: 'C34.0' }, { name: 'head of pancreas', icdo3_code: 'C25.0' }]
    sites.each do |site|
      abstractor_object_value = Abstractor::AbstractorObjectValue.create(:value => "#{site[:name]} (#{site[:icdo3_code]})")
      Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: @abstractor_abstraction_schema_has_cancer_site, abstractor_object_value: abstractor_object_value).first_or_create
      Abstractor::AbstractorObjectValueVariant.create(:abstractor_object_value => abstractor_object_value, :value => site[:name])
    end

    @abstractor_subject_abstraction_schema_has_cancer_site = Abstractor::AbstractorSubject.create(:subject_type => NoteStableIdentifier.to_s, :abstractor_abstraction_schema => @abstractor_abstraction_schema_has_cancer_site, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_pathology_cases.id)
    @abstractor_abstraction_source_has_cancer_site = Abstractor::AbstractorAbstractionSource.create(abstractor_subject: @abstractor_subject_abstraction_schema_has_cancer_site, from_method: 'note_text', abstractor_abstraction_source_type: custom_nlp_suggestion_source_type, custom_nlp_provider:  'custom_nlp_provider_name', abstractor_rule_type: abstractor_rule_type_value)
    @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
    @no_matching_concept = FactoryGirl.create(:no_matching_concept)
    @undefined_concept = FactoryGirl.create(:undefined_concept)
    @person = FactoryGirl.create(:person)
  end

  describe "abstracting" do
    it 'determines a suggestion endpiont', focus: false do
      expect(Abstractor::CustomNlpProvider.determine_suggestion_endpoint('custom_nlp_provider_name')).to eq('http://custom-nlp-provider.test/suggest')
    end

    it 'posts a message to a custom nlp provider to generate suggestions', focus: false do
      Rails.application.routes.default_url_options[:host] = 'https://moomin.com'

      text = 'Looks like metastatic carcinoma to me.'
      @note_dummy = FactoryGirl.create(:note, person: @person, note_text: text)
      @note_stable_identifier_dummy = FactoryGirl.create(:note_stable_identifier, note: @note_dummy)
      stub_request(:post, "http://custom-nlp-provider.test/suggest").
        to_return(:status => 200, :body => "", :headers => {})

      @note_stable_identifier_dummy.abstract(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_cancer_histology.id])

      text = 'Looks like metastatic carcinoma to me.'
      @note = FactoryGirl.create(:note, person: @person, note_text: text)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)

      abstractor_abstraction_id = Abstractor::AbstractorAbstraction.maximum(:id)
      abstractor_abstraction_id+=1

      body = "{\"abstractor_abstraction_schema_id\":#{@abstractor_abstraction_schema_has_cancer_histology.id},\"abstractor_abstraction_schema_uri\":\"https://moomin.com/abstractor_abstraction_schemas/#{@abstractor_abstraction_schema_has_cancer_histology.id}.json\",\"abstractor_abstraction_abstractor_suggestions_uri\":\"https://moomin.com/abstractor_abstractions/#{abstractor_abstraction_id}/abstractor_suggestions.json\",\"abstractor_abstraction_id\":#{abstractor_abstraction_id},\"abstractor_abstraction_source_id\":#{@abstractor_abstraction_source_has_cancer_histology.id},\"source_id\":#{@note_stable_identifier.id},\"source_type\":\"NoteStableIdentifier\",\"source_method\":\"note_text\",\"text\":\"#{text}\"}"
      stub_request(:post, "http://custom-nlp-provider.test/suggest").
        with(:body => body,
              headers: {'Authorization'=>'Basic dGVzdHVzZXI6cGFzc3dvcmQ=', 'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => "", :headers => {})

      @note_stable_identifier.abstract(abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_cancer_histology.id])

      abstractor_abstraction = @note_stable_identifier.abstractor_abstractions_by_abstraction_schemas({abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_cancer_histology.id] }).first
      abstractor_abstraction_soruce = @abstractor_subject_abstraction_schema_has_cancer_histology.abstractor_abstraction_sources.first
      expect(a_request(:post, "http://custom-nlp-provider.test/suggest").with(body: body, headers: { 'Content-Type' => 'application/json' })).to have_been_made
    end

    it 'posts a message to a custom nlp provider to generate multiple suggestions', focus: false do
      Rails.application.routes.default_url_options[:host] = 'https://moomin.com'

      text = 'Looks like metastatic carcinoma to me.'
      @note_dummy = FactoryGirl.create(:note, person: @person, note_text: text)
      @note_stable_identifier_dummy = FactoryGirl.create(:note_stable_identifier, note: @note_dummy)
      stub_request(:post, "http://custom-nlp-provider.test/multiple_suggest").
        to_return(:status => 200, :body => "", :headers => {})
      @note_stable_identifier_dummy.abstract_multiple

      abstractor_abstraction_id = Abstractor::AbstractorAbstraction.maximum(:id)
      abstractor_abstraction_id+=1

      text = 'Looks like metastatic carcinoma to me.'
      @note = FactoryGirl.create(:note, person: @person, note_text: text)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      body = "{\"source_id\":#{@note_stable_identifier.id},\"source_type\":\"NoteStableIdentifier\",\"source_method\":\"note_text\",\"abstractor_rules_uri\":\"https://moomin.com/abstractor_rules.json\",\"text\":\"Looks like metastatic carcinoma to me.\",\"abstractor_abstraction_schemas\":[{\"abstractor_abstraction_schema_id\":#{@abstractor_abstraction_schema_has_cancer_histology.id},\"abstractor_abstraction_schema_uri\":\"https://moomin.com/abstractor_abstraction_schemas/#{@abstractor_abstraction_schema_has_cancer_histology.id}.json\",\"abstractor_abstraction_abstractor_suggestions_uri\":\"https://moomin.com/abstractor_abstractions/#{abstractor_abstraction_id}/abstractor_suggestions.json\",\"abstractor_abstraction_id\":#{abstractor_abstraction_id},\"abstractor_abstraction_source_id\":#{@abstractor_abstraction_source_has_cancer_histology.id},\"abstractor_subject_id\":#{@abstractor_subject_abstraction_schema_has_cancer_histology.id},\"namespace_type\":\"#{Abstractor::AbstractorNamespace.to_s}\",\"namespace_id\":#{@abstractor_namespace_pathology_cases.id},\"abstractor_rule_type\":\"#{@abstractor_abstraction_source_has_cancer_histology.abstractor_rule_type.name}\",\"updated_at\":\"#{@abstractor_abstraction_schema_has_cancer_histology.updated_at.iso8601.to_s}\"},{\"abstractor_abstraction_schema_id\":#{@abstractor_abstraction_schema_has_cancer_site.id},\"abstractor_abstraction_schema_uri\":\"https://moomin.com/abstractor_abstraction_schemas/#{@abstractor_abstraction_schema_has_cancer_site.id}.json\",\"abstractor_abstraction_abstractor_suggestions_uri\":\"https://moomin.com/abstractor_abstractions/#{abstractor_abstraction_id+1}/abstractor_suggestions.json\",\"abstractor_abstraction_id\":#{abstractor_abstraction_id+1},\"abstractor_abstraction_source_id\":#{@abstractor_abstraction_source_has_cancer_site.id},\"abstractor_subject_id\":#{@abstractor_subject_abstraction_schema_has_cancer_site.id},\"namespace_type\":\"#{Abstractor::AbstractorNamespace.to_s}\",\"namespace_id\":#{@abstractor_namespace_pathology_cases.id},\"abstractor_rule_type\":\"#{@abstractor_abstraction_source_has_cancer_site.abstractor_rule_type.name}\",\"updated_at\":\"#{@abstractor_abstraction_schema_has_cancer_site.updated_at.iso8601.to_s}\"}]}"
      stub_request(:post, "http://custom-nlp-provider.test/multiple_suggest").
        with(:body => body,
             headers: {'Authorization'=>'Basic dGVzdHVzZXI6cGFzc3dvcmQ=', 'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => "", :headers => {})

      @note_stable_identifier.abstract_multiple
      abstractor_abstraction_has_cancer_histology = @note_stable_identifier.abstractor_abstractions_by_abstraction_schemas({abstractor_abstraction_schema_ids: [@abstractor_abstraction_schema_has_cancer_histology.id] }).first

      # File.write("#{Rails.root}/doc/api/post_note_and_abstractor_schemas.json", body)
      expect(a_request(:post, "http://custom-nlp-provider.test/multiple_suggest").with(body: body, headers: { 'Content-Type' => 'application/json' })).to have_been_made
    end
  end
end