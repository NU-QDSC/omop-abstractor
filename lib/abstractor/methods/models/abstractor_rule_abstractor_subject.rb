module Abstractor
  module Methods
    module Models
      module AbstractorRuleAbstractorSubject
        def self.included(base)
          base.send :include, SoftDelete
          base.send :has_paper_trail

          # Associations
          base.send :belongs_to, :abstractor_rule
          base.send :belongs_to, :abstractor_subject
        end
      end
    end
  end
end
