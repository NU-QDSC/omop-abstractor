module Abstractor
  module Methods
    module Models
      module AbstractorSectionMentionType
        def self.included(base)
          # Associations
          base.send :has_many, :abstractor_sections
        end
      end
    end
  end
end