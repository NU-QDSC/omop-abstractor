module Abstractor
  module Methods
    module Models
      module AbstractorAbstractionSourceSection
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_abstraction_source
          base.send :belongs_to, :abstractor_section
          base.send(:include, InstanceMethods)
          base.extend(ClassMethods)
        end

        # Instance Methods
        module InstanceMethods
        end

        # Class Methods
        module ClassMethods
        end
      end
    end
  end
end