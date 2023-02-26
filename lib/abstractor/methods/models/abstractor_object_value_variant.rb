module Abstractor
  module Methods
    module Models
      module AbstractorObjectValueVariant
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_object_value
          base.send :has_many, :abstractor_suggestion_object_value_variants
          base.send :has_many, :abstractor_suggestions, through: :abstractor_suggestion_object_value_variants

          # Validations
          base.send :validates_presence_of, :value

          # Hooks
          base.send :before_save, :soft_delete_abstractor_suggestions
          base.send :after_create,    :update_abstractor_object_value
          base.send :after_update,    :update_abstractor_object_value
          base.send :after_destroy,   :update_abstractor_object_value
          base.send :after_touch,     :update_abstractor_object_value

          base.send(:include, InstanceMethods)
        end

        module InstanceMethods
          def update_abstractor_object_value
            abstractor_object_value.touch if abstractor_object_value && abstractor_object_value.persisted?
          end

          def used?
            @used = @used || self.abstractor_suggestions.any?
          end

          def soft_delete_abstractor_suggestions
            if self.deleted_at.present? && self.deleted_at_changed?
              as = self.abstractor_suggestions.not_deleted.where('accepted IS NULL OR accepted = ?', false)
              as.each do |abstractor_suggestion|
                if abstractor_suggestion.abstractor_object_value_variants.not_deleted.size == 1
                  abstractor_suggestion.soft_delete!
                  if abstractor_suggestion.abstractor_abstraction.abstractor_suggestions.not_deleted.empty?
                    abstractor_abstraction = abstractor_suggestion.abstractor_abstraction
                    abstractor_abstraction_source = abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first
                    abstractor_suggestion.abstractor_abstraction.abstractor_subject.create_unknown_abstractor_suggestion(abstractor_abstraction.about, abstractor_abstraction, abstractor_abstraction_source)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end