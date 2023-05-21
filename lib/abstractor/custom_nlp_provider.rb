module Abstractor
  module CustomNlpProvider
    ##
    # Determines the suggestion endpoint for the passed in custom NLP provider.
    #
    # The endpoint is assumed to be configured in config/abstractor/custom_nlp_providers.yml.
    # A template configratuon file can be generated in the host application by
    # calling the rake task abstractor:custom_nlp_provider.
    # @param [String] custom_nlp_provider The name of the custom NLP provider whose endpoint should be determined.
    # @return [String] The endpoint.
    def self.determine_suggestion_endpoint(custom_nlp_provider)
      suggestion_endpoint = YAML.load_file("#{Rails.root}/config/abstractor/custom_nlp_providers.yml")[custom_nlp_provider]['suggestion_endpoint'][Rails.env]
    end

    def self.determine_multiple_suggestion_file_location(custom_nlp_provider)
      multiple_suggestion_file_location = nil
      provider = YAML.load_file("#{Rails.root}/config/abstractor/custom_nlp_providers.yml")[custom_nlp_provider]
      if provider.present? && provider['multiple_suggestion_file_location']
        multiple_suggestion_file_location = provider['multiple_suggestion_file_location'][Rails.env]
      end
      multiple_suggestion_file_location
    end

    def self.determine_multiple_suggestion_endpoint(custom_nlp_provider)
      multiple_suggestion_endpoint = nil
      provider = YAML.load_file("#{Rails.root}/config/abstractor/custom_nlp_providers.yml")[custom_nlp_provider]
      if provider.present? && provider['multiple_suggestion_endpoint']
        multiple_suggestion_endpoint = provider['multiple_suggestion_endpoint'][Rails.env]
      end
      multiple_suggestion_endpoint
    end

    def self.determine_suggestion_endpoint_credentials(custom_nlp_provider)
      suggestion_endpoint_credentials = YAML.load_file("#{Rails.root}/config/abstractor/custom_nlp_providers.yml")[custom_nlp_provider]['suggestion_endpoint_credentials'][Rails.env]
    end

    ##
    # Formats the JSON body in preparation for submision to a custom NLP provider endpoint.
    #
    # @example Example of body prepared by Abstractor to submit to an custom NLP provider
    #   {
    #     "abstractor_abstraction_schema_id":1,
    #     "abstractor_abstraction_schema_uri":"https://moomin.com/abstractor_abstraction_schemas/1",
    #     "abstractor_abstraction_id":1,
    #     "abstractor_abstraction_source_id":1,
    #     "source_type":  "PathologyCase",
    #     "source_method": "note_text",
    #     "text": "The patient has a diagnosis of glioblastoma.  GBM does not have a good prognosis.  But I can't rule out meningioma."
    #   }
    #
    #
    # @param [Abstractor::AbstractorAbstraction] abstractor_abstraction The abstractor abstraction to be formated for submission to a custom nlp provider endpoint.
    # @param [Abstractor::AbstractorAbstractionSource] abstractor_abstraction_source The abstractor abstraction source to be formated for submission to a custom nlp provider endpoint.
    # @param [String] abstractor_text The text be formated for submission to a custom nlp provider endpoint.
    # @param [Hash] source The hash of values representing the source for submission to a custom nlp provider endpoint.
    # @return [Hash] The formatted body.
    def self.format_body_for_suggestion_endpoint(abstractor_abstraction, abstractor_abstraction_source, abstractor_text, source)
      if Rails.application.config.relative_url_root
        abstractor_abstraction_schema_uri =  Rails.application.routes.url_helpers.abstractor_abstraction_schema_url(abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema, script_name: Rails.application.config.relative_url_root, format: :json)
        abstractor_abstraction_abstractor_suggestions_uri = Abstractor::Engine.routes.url_helpers.abstractor_abstraction_abstractor_suggestions_url(abstractor_abstraction, script_name: Rails.application.config.relative_url_root,format: :json)
      else
        abstractor_abstraction_schema_uri =  Rails.application.routes.url_helpers.abstractor_abstraction_schema_url(abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema,  format: :json)
        abstractor_abstraction_abstractor_suggestions_uri =  Rails.application.routes.url_helpers.abstractor_abstraction_abstractor_suggestions_url(abstractor_abstraction, format: :json)
      end

      {
        abstractor_abstraction_schema_id: abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.id,
        abstractor_abstraction_schema_uri: abstractor_abstraction_schema_uri,
        abstractor_abstraction_abstractor_suggestions_uri: abstractor_abstraction_abstractor_suggestions_uri,
        abstractor_abstraction_id: abstractor_abstraction.id,
        abstractor_abstraction_source_id: abstractor_abstraction_source.id,
        source_id: source[:source_id],
        source_type: source[:source_type].to_s,
        source_method: source[:source_method],
        text: abstractor_text
      }
    end

    def self.format_body_for_multiple_suggestion_endpoint(abstractor_abstractions, abstractor_abstraction_sources, abstractor_text, source, namespace_type, namespace_id)
      if  Rails.env.staging? || Rails.env.production?
        protocol = 'https'
      else
        protocol = 'http'
      end
      if Rails.application.config.relative_url_root
        abstractor_rules_uri =  Rails.application.routes.url_helpers.abstractor_rules_url(script_name: Rails.application.config.relative_url_root, format: :json, protocol: protocol)
      else
        abstractor_rules_uri =  Rails.application.routes.url_helpers.abstractor_rules_url(format: :json)
      end

      body = {
        source_id: source[:source_id],
        source_type: source[:source_type].to_s,
        source_method: source[:source_method],
        note_abstractor_suggestions_uri: Rails.application.routes.url_helpers.abstractor_suggestions_note_stable_identifier_url(source[:source_id], format: :json, protocol: protocol),
        abstractor_rules_uri: abstractor_rules_uri,
        text: abstractor_text,
        namespace_type: namespace_type,
        namespace_id: namespace_id,
        abstractor_abstraction_schemas: [],
        abstractor_sections: []
      }

      if namespace_type.present? && namespace_id.present?
        abstractor_namespace = Abstractor::AbstractorNamespace.where(id: namespace_id).first
        if abstractor_namespace
          abstractor_namespace.abstractor_namespace_sections.each do |abstractor_namespace_section|
            abstractor_section = { name: abstractor_namespace_section.abstractor_section.name, section_mention_type: abstractor_namespace_section.abstractor_section.abstractor_section_mention_type.name, section_name_variants: [] }
            abstractor_namespace_section.abstractor_section.abstractor_section_name_variants.each do |abstractor_section_name_variant|
              abstractor_section[:section_name_variants] << { name: abstractor_section_name_variant.name }
            end
            body[:abstractor_sections] << abstractor_section
          end
        end
      end

      abstractor_abstractions.each do |abstractor_abstraction|
        abstractor_abstraction_source = abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources & abstractor_abstraction_sources
        abstractor_abstraction_source = abstractor_abstraction_source.first
        abstractor_abstraction_schema = abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema
        if Rails.application.config.relative_url_root
          abstractor_abstraction_schema_uri =  Rails.application.routes.url_helpers.abstractor_abstraction_schema_url(abstractor_abstraction_schema, script_name: Rails.application.config.relative_url_root, format: :json, protocol: protocol)
          abstractor_abstraction_abstractor_suggestions_uri = Abstractor::Engine.routes.url_helpers.abstractor_abstraction_abstractor_suggestions_url(abstractor_abstraction, script_name: Rails.application.config.relative_url_root,format: :json, protocol: protocol)
        else
          abstractor_abstraction_schema_uri =  Rails.application.routes.url_helpers.abstractor_abstraction_schema_url(abstractor_abstraction_schema,  format: :json, protocol: protocol)
          abstractor_abstraction_abstractor_suggestions_uri =  Rails.application.routes.url_helpers.abstractor_abstraction_abstractor_suggestions_url(abstractor_abstraction, format: :json, protocol: protocol)
        end

        abstractor_abstraction_schema = {
          abstractor_abstraction_schema_id: abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.id,
          abstractor_abstraction_schema_uri: abstractor_abstraction_schema_uri,
          abstractor_abstraction_abstractor_suggestions_uri: abstractor_abstraction_abstractor_suggestions_uri,
          abstractor_abstraction_id: abstractor_abstraction.id,
          abstractor_abstraction_source_id: abstractor_abstraction_source.id,
          abstractor_subject_id: abstractor_abstraction.abstractor_subject.id,
          namespace_type: abstractor_abstraction.abstractor_subject.namespace_type,
          namespace_id: abstractor_abstraction.abstractor_subject.namespace_id,
          abstractor_rule_type: abstractor_abstraction_source.abstractor_rule_type.name,
          abstractor_object_type: abstractor_abstraction_schema.abstractor_object_type.value,
          updated_at: abstractor_abstraction_schema.updated_at.iso8601.to_s
        }
        body[:abstractor_abstraction_schemas] << abstractor_abstraction_schema
      end
      body
    end
  end
end