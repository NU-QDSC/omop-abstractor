module Abstractor
  module Methods
    module Models
      module AbstractorAbstractionSchemaObjectValue
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_abstraction_schema
          base.send :belongs_to, :abstractor_object_value

          # Hooks
          base.send :after_create,  :update_abstractor_abstraction_schema
          base.send :after_update,  :update_abstractor_abstraction_schema
          base.send :after_destroy, :update_abstractor_abstraction_schema
          base.send :after_touch,   :update_abstractor_abstraction_schema
        end

        # Instance Methods
        def update_abstractor_abstraction_schema
          abstractor_abstraction_schema.touch if abstractor_abstraction_schema && abstractor_abstraction_schema.persisted?
        end
      end
    end
  end
end