require 'rails_helper'
describe AbstractorSuggestionsController, :type => :request do
  let(:accept_json) { { "Accept" => "application/json" } }
  let(:json_content_type) { { "Content-Type" => "application/json" } }
  let(:accept_and_return_json) { accept_json.merge(json_content_type) }

  describe "POST /abstractor_abstractions/:abstractor_abstraction_id/abstractor_suggestions" do
    before(:each) do
      Abstractor::Setup.system
      OmopAbstractor::SpecSetup.encounter_note
      @no_matching_concept = FactoryGirl.create(:no_matching_concept)
      @undefined_concept_class = FactoryGirl.create(:undefined_concept_class)
      @undefined_concept = FactoryGirl.create(:undefined_concept)
      @person = FactoryGirl.create(:person)
      @pii_name = FactoryGirl.create(:pii_name, person_id: @person.person_id)

      @abstractor_namespace_encoutner_note = Abstractor::AbstractorNamespace.where(name: 'Encounter Note').first
      [{'Note Text' => 'Looking good. KPS: 100'}].each_with_index do |encounter_note_hash, i|
        note = FactoryGirl.create(:note, person: @person, note_text: encounter_note_hash['Note Text'])
        note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: note)
        note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_encoutner_note.id)
      end

      AbstractorSuggestionsController.any_instance.stub(:authenticate_user!).and_return(true)
      @abstractor_namespace_pathology_case = Abstractor::AbstractorNamespace.where(name: 'Pathology Case', subject_type: NoteStableIdentifier.to_s, joins_clause: '', where_clause: '').first_or_create
      custom_nlp_provider = 'custom_nlp_provider_name'
      Rails.application.routes.default_url_options[:host] = 'https://moomin.com'
      list_object_type = Abstractor::AbstractorObjectType.where(value: 'list').first
      custom_nlp_suggestion_source_type = Abstractor::AbstractorAbstractionSourceType.where(name: 'custom nlp suggestion').first
      abstractor_abstraction_schema = Abstractor::AbstractorAbstractionSchema.where(
        predicate: 'has_cancer_histology',
        display_name: 'Cancer Histology',
        abstractor_object_type: list_object_type,
        preferred_name: 'cancer histology').first_or_create

      histologies =  [{ name: 'glioblastoma, nos', icdo3_code: '9440/3' }, { name: 'meningioma, nos', icdo3_code: '9530/0' }]
      histologies.each do |histology|
        abstractor_object_value = FactoryGirl.create(:abstractor_object_value, :value => "#{histology[:name]} (#{histology[:icdo3_code]})")
        Abstractor::AbstractorAbstractionSchemaObjectValue.where(abstractor_abstraction_schema: abstractor_abstraction_schema,abstractor_object_value: abstractor_object_value).first_or_create
        Abstractor::AbstractorObjectValueVariant.create(:abstractor_object_value => abstractor_object_value, :value => histology[:name])
        histology_synonyms = [{ synonym_name: 'glioblastoma', icdo3_code: '9440/3' }, { synonym_name: 'spongioblastoma multiforme', icdo3_code: '9440/3' }, { synonym_name: 'gbm', icdo3_code: '9440/3' }, { synonym_name: 'meningioma', icdo3_code: '9530/0' }, { synonym_name: 'leptomeningioma', icdo3_code: '9530/0' }, { synonym_name: 'meningeal fibroblastoma', icdo3_code: '9530/0' }]
        histology_synonyms.select { |histology_synonym| histology.to_hash[:icdo3_code] == histology_synonym.to_hash[:icdo3_code] }.each do |histology_synonym|
          Abstractor::AbstractorObjectValueVariant.create(:abstractor_object_value => abstractor_object_value, :value => histology_synonym[:synonym_name])
        end
      end

      abstractor_subject = Abstractor::AbstractorSubject.create(:subject_type => NoteStableIdentifier.to_s, :abstractor_abstraction_schema => abstractor_abstraction_schema, namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id: @abstractor_namespace_pathology_case.id)
      @from_method = 'note_text'
      abstractor_rule_type_name_value = Abstractor::AbstractorRuleType.where(name: 'name/value', description:'search for value associated with name').first
      @abstractor_abstraction_source = Abstractor::AbstractorAbstractionSource.create!(abstractor_subject: abstractor_subject, from_method: @from_method, abstractor_abstraction_source_type: custom_nlp_suggestion_source_type, custom_nlp_provider: custom_nlp_provider, abstractor_rule_type: abstractor_rule_type_name_value)
      @abstractor_abstraction_schema_has_cancer_histology = Abstractor::AbstractorAbstractionSchema.where(predicate: 'has_cancer_histology').first
      @abstractor_subject_abstraction_schema_has_cancer_histology = Abstractor::AbstractorSubject.where(subject_type: NoteStableIdentifier.to_s, abstractor_abstraction_schema_id:@abstractor_abstraction_schema_has_cancer_histology.id).first
      abstractor_abstraction_id = Abstractor::AbstractorAbstraction.maximum(:id)
      abstractor_abstraction_id+=1
      note_text = "The patient has a diagnosis of glioblastoma.  GBM does not have a good prognosis.  But I can't rule out meningioma."
      @note = FactoryGirl.create(:note, person: @person, note_text: note_text)
      @note_stable_identifier = FactoryGirl.create(:note_stable_identifier, note: @note)
      stub_request(:post, "http://custom-nlp-provider.test/suggest").
        with(:body => "{\"abstractor_abstraction_schema_id\":#{@abstractor_abstraction_schema_has_cancer_histology.id},\"abstractor_abstraction_schema_uri\":\"https://moomin.com/abstractor_abstraction_schemas/#{@abstractor_abstraction_schema_has_cancer_histology.id}.json\",\"abstractor_abstraction_abstractor_suggestions_uri\":\"https://moomin.com/abstractor_abstractions/#{abstractor_abstraction_id}/abstractor_suggestions.json\",\"abstractor_abstraction_id\":#{abstractor_abstraction_id},\"abstractor_abstraction_source_id\":#{@abstractor_abstraction_source.id},\"source_id\":#{@note_stable_identifier.id},\"source_type\":\"NoteStableIdentifier\",\"source_method\":\"note_text\",\"text\":\"The patient has a diagnosis of glioblastoma.  GBM does not have a good prognosis.  But I can't rule out meningioma.\"}",
             :headers => {'Content-Type'=>'application/json'}).
        to_return(:status => 200, :body => "", :headers => {})
      @note_stable_identifier.abstract(namespace_type: Abstractor::AbstractorNamespace.to_s, namespace_id:  @abstractor_namespace_pathology_case.id)
      @abstractor_abstraciton = @note_stable_identifier.reload.abstractor_abstractions.first
      abstractor_section_type_custom = Abstractor::AbstractorSectionType.where(name: Abstractor::Enum::ABSTRACTOR_SECTION_TYPE_CUSTOM).first

      @abstractor_section = FactoryGirl.create(:abstractor_section, abstractor_section_type: abstractor_section_type_custom, name: 'Diagnosis')
      @abstractor_section_name_variant = FactoryGirl.create(:abstractor_section_name_variant, abstractor_section: @abstractor_section, name: 'Diagnosis Alternative')
      @abstractor_abstraction_source_section = FactoryGirl.create(:abstractor_abstraction_source_section, abstractor_abstraction_source: @abstractor_abstraction_source, abstractor_section: @abstractor_section)
    end

    it "creates a suggestion", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: "glioblastoma",
          unknown: nil,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: "glioblastoma",
                      sentence_match_value: "The patient has a diagnosis of glioblastoma."
                   },
                   {
                      match_value: "gbm",
                      sentence_match_value: "GBM does not have a good prognosis."
                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      # File.write("#{Rails.root}/doc/api/post_suggestion.json", abstractor_suggestion.to_json)
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to eq('glioblastoma')
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array(["glioblastoma", "gbm"])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array(["GBM does not have a good prognosis.", "The patient has a diagnosis of glioblastoma."])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.accepted).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted).to be_falsy
    end

    it "creates a suggestion and sets accepted to false and system accepted to false and system rejected to true if it is explicitly marked as 'negated'", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: "glioblastoma",
          unknown: nil,
          not_applicable: nil,
          negated: true,
          suggestion_sources:[
                      {
                      match_value: "glioblastoma",
                      sentence_match_value: "The patient does not have a diagnosis of glioblastoma."
                   },
                   {
                      match_value: "gbm",
                      sentence_match_value: "GBM does not have a good prognosis."
                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      # File.write("#{Rails.root}/doc/api/post_suggestion.json", abstractor_suggestion.to_json)
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to eq('glioblastoma')
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array(["glioblastoma", "gbm"])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array(["GBM does not have a good prognosis.", "The patient does not have a diagnosis of glioblastoma."])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.accepted).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected_reason).to eq(Abstractor::Enum::ABSTRACTOR_SUGGESTION_SYSTEM_REJECTED_REASON_NEGATED)
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted).to be_falsy
    end

    it "creates a suggestion and sets accepted to true and the system accepted to true if a section name matches a section name in abstractor_abstraction_source_sections", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: "glioblastoma",
          unknown: nil,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: "glioblastoma",
                      sentence_match_value: "The patient has a diagnosis of glioblastoma.",
                      section_name: 'Diagnosis'

                   },
                   {
                      match_value: "gbm",
                      sentence_match_value: "GBM does not have a good prognosis.",
                      section_name: 'Diagnosis'

                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      # File.write("#{Rails.root}/doc/api/post_suggestion.json", abstractor_suggestion.to_json)
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to eq('glioblastoma')
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array(["glioblastoma", "gbm"])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array(["GBM does not have a good prognosis.", "The patient has a diagnosis of glioblastoma."])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.accepted).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted_reason).to eq(Abstractor::Enum::ABSTRACTOR_SUGGESTION_SYSTEM_ACCEPTED_REASON_SECTION_MATCH)
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected_reason).to be_nil
    end

    it "creates a suggestion and sets accepted to true and the system accepted to true if a section name matches a section name variant in abstractor_abstraction_source_sections", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: "glioblastoma",
          unknown: nil,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: "glioblastoma",
                      sentence_match_value: "The patient has a diagnosis of glioblastoma.",
                      section_name: 'Diagnosis Alternative'
                   },
                   {
                      match_value: "gbm",
                      sentence_match_value: "GBM does not have a good prognosis.",
                      section_name: 'Diagnosis Alternative'
                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      # File.write("#{Rails.root}/doc/api/post_suggestion.json", abstractor_suggestion.to_json)
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to eq('glioblastoma')
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array(["glioblastoma", "gbm"])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array(["GBM does not have a good prognosis.", "The patient has a diagnosis of glioblastoma."])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.accepted).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted_reason).to eq(Abstractor::Enum::ABSTRACTOR_SUGGESTION_SYSTEM_ACCEPTED_REASON_SECTION_MATCH)
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected_reason).to be_nil
    end

    it "creates a suggestion and sets accepted to false and system accepted to false and system rejected to true if a section name does not match a section name in abstractor_abstraction_source_sections and section required is true", focus: false do
      @abstractor_abstraction_source.section_required = true
      @abstractor_abstraction_source.save!
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: "glioblastoma",
          unknown: nil,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: "glioblastoma",
                      sentence_match_value: "The patient has a diagnosis of glioblastoma.",
                      section_name: 'Other section'

                   },
                   {
                      match_value: "gbm",
                      sentence_match_value: "GBM does not have a good prognosis.",
                      section_name: 'Other section'

                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      # File.write("#{Rails.root}/doc/api/post_suggestion.json", abstractor_suggestion.to_json)
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to eq('glioblastoma')
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array(["glioblastoma", "gbm"])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array(["GBM does not have a good prognosis.", "The patient has a diagnosis of glioblastoma."])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.accepted).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted_reason).to be_nil
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected_reason).to eq(Abstractor::Enum::ABSTRACTOR_SUGGESTION_SYSTEM_REJECTED_REASON_NO_SECTION_MATCH)
    end

    it "creates a suggestion and sets accepted to nil and system accepted to false and system rejected to false if a section name does not match a section name in abstractor_abstraction_source_sections and section required is false", focus: true do
      @abstractor_abstraction_source.section_required = false
      @abstractor_abstraction_source.save!
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: "glioblastoma",
          unknown: nil,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: "glioblastoma",
                      sentence_match_value: "The patient has a diagnosis of glioblastoma.",
                      section_name: 'Other section'

                   },
                   {
                      match_value: "gbm",
                      sentence_match_value: "GBM does not have a good prognosis.",
                      section_name: 'Other section'

                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      # File.write("#{Rails.root}/doc/api/post_suggestion.json", abstractor_suggestion.to_json)
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to eq('glioblastoma')
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array(["glioblastoma", "gbm"])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array(["GBM does not have a good prognosis.", "The patient has a diagnosis of glioblastoma."])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.accepted).to be_nil
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_accepted_reason).to be_nil
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected).to be_falsy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.system_rejected_reason).to be_nil
    end

    it "creates an 'unknown' suggestion", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: nil,
          unknown: true,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: nil,
                      sentence_match_value: nil
                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.unknown).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to be_nil
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array([nil])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array([nil])
    end

    it "does not creates multiple 'unknown' suggestions upon re-abstraction", focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { abstractor_abstractor_suggestion:
        {
          abstractor_abstraction_source_id: @abstractor_abstraction_source.id,
          source_id: @note_stable_identifier.id,
          source_type:@note_stable_identifier.class.to_s,
          source_method: @from_method,
          value: nil,
          unknown: true,
          not_applicable: nil,
          suggestion_sources:[
                      {
                      match_value: nil,
                      sentence_match_value: nil
                   }
                ]
        }
      }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      expect(response.status).to eq 201
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.unknown).to be_truthy
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.suggested_value).to be_nil
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:match_value)).to match_array([nil])
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.first.abstractor_suggestion_sources.map(&:sentence_match_value)).to match_array([nil])
      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      expect(@abstractor_abstraciton.reload.abstractor_suggestions.size).to eq(1)
    end

    it 'returns an error status code if and invalid body is posted', focus: false do
      headers = { "Accept" => "application/json" }
      abstractor_suggestion =  { moomin: 'little my' }

      post "/abstractor_abstractions/#{@abstractor_abstraciton.id}/abstractor_suggestions", params: abstractor_suggestion, headers: headers
      expect(response.status).to eq 422
    end
  end
end