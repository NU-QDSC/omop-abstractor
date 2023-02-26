module Abstractor
  module Methods
    module Models
      module AbstractorAbstractionGroupMember
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_abstraction_group
          base.send :belongs_to, :abstractor_abstraction, optional: true

          base.send :validates_associated, :abstractor_abstraction

          # base.send :attr_accessible, :abstractor_abstraction_group, :abstractor_abstraction_group_id, :abstractor_abstraction, :abstractor_abstraction_id, :deleted_at
          base.send(:include, InstanceMethods)
          base.extend(ClassMethods)
        end
        module InstanceMethods
          def anchor?
            abstractor_abstraction.abstractor_subject.anchor
          end          
        end
        module ClassMethods
        end
      end
    end
  end
end
