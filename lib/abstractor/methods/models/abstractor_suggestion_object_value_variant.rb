module Abstractor
  module Methods
    module Models
      module AbstractorSuggestionObjectValueVariant
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_suggestion
          base.send :belongs_to, :abstractor_object_value_variant

        end
      end
    end
  end
end