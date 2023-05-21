module Abstractor
  module Methods
    module Models
      module AbstractorRule
        def self.included(base)
          base.send :include, SoftDelete
          base.send :has_paper_trail

          # Associations
          base.send :has_many, :abstractor_rule_abstractor_subjects

          base.extend(ClassMethods)
        end

        module ClassMethods
          def search_by_abstractor_subjects_ids(abstractor_subject_ids)
            Abstractor::AbstractorRule.not_deleted.where(['EXISTS(SELECT 1 FROM abstractor_rule_abstractor_subjects WHERE abstractor_rules.id = abstractor_rule_abstractor_subjects.abstractor_rule_id AND abstractor_rule_abstractor_subjects.deleted_at IS NULL AND abstractor_rule_abstractor_subjects.abstractor_subject_id IN(?))', abstractor_subject_ids])
          end
        end
      end
    end
  end
end