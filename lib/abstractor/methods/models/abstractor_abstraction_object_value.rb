module Abstractor
  module Methods
    module Models
      module AbstractorAbstractionObjectValue
        def self.included(base)
          base.send :include, SoftDelete
          base.send :has_paper_trail

          # Associations
          base.send :belongs_to, :abstractor_abstraction
          base.send :belongs_to, :abstractor_object_value

          base.send(:include, InstanceMethods)
          base.extend(ClassMethods)
        end

        module InstanceMethods
        end

        module ClassMethods
        end
      end
    end
  end
end