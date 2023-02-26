module OmopAbstractor
  module Setup
    def self.normalize(value)
      normalized_values = []
      words = value.split(',').map(&:strip) - ['nos']
      if words.size == 1
        normalized_values << words.first
      end
      if words.size > 1
        normalized_values << value
        normalized_values << words.reverse.join(' ')
        normalized_values <<  words.join(' ')
      end
      normalized_values
    end

    def self.object_value_exists?(abstractor_abstraction_schema, value)
      (Abstractor::AbstractorObjectValue.joins(:abstractor_abstraction_schema_object_values).where('abstractor_object_values.deleted_at IS NULL AND abstractor_abstraction_schema_object_values.abstractor_abstraction_schema_id = ? AND lower(abstractor_object_values.value) = ?', abstractor_abstraction_schema.id, value.downcase).any?  || Abstractor::AbstractorObjectValueVariant.joins(abstractor_object_value: :abstractor_abstraction_schema_object_values).where('abstractor_object_value_variants.deleted_at IS NULL AND abstractor_abstraction_schema_object_values.abstractor_abstraction_schema_id = ? AND lower(abstractor_object_value_variants.value) = ?', abstractor_abstraction_schema.id, value.downcase).any?)
    end

    def self.object_value_variant_exists?(vocabulary_code, value)
      Abstractor::AbstractorObjectValueVariant.joins(:abstractor_object_value).where('abstractor_object_values.deleted_at IS NULL AND abstractor_object_value_variants.deleted_at IS NULL AND abstractor_object_values.vocabulary_code = ? AND lower(abstractor_object_value_variants.value) = ?', vocabulary_code, value.downcase).any?
    end
  end
end