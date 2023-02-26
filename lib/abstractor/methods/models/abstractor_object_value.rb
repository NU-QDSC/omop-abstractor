module Abstractor
  module Methods
    module Models
      module AbstractorObjectValue
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :has_many, :abstractor_object_value_variants
          base.send :has_many, :abstractor_abstraction_schema_object_values
          base.send :has_many, :abstractor_abstraction_schemas, through: :abstractor_abstraction_schema_object_values
          base.send :has_many, :abstractor_abstraction_object_values
          base.send :has_many, :abstractor_abstractions, through: :abstractor_abstraction_object_values
          base.send :has_many, :abstractor_suggestion_object_values
          base.send :has_many, :abstractor_suggestions, through: :abstractor_suggestion_object_values

          # Validations
          base.send :validates_presence_of, :value
          base.send :validates_presence_of, :vocabulary_code
          base.send :validates_associated, :abstractor_object_value_variants

          # Hooks
          base.send :before_save, :set_soft_delete_abstractor_object_value_variants
          base.send :before_save, :soft_delete_abstractor_suggestions
          base.send :before_save, :soft_delete_abstractor_object_value_variants
          base.send :after_update,  :update_abstractor_abstraction_schema_object_values
          base.send :after_destroy, :update_abstractor_abstraction_schema_object_values
          base.send :after_touch,   :update_abstractor_abstraction_schema_object_values

          base.send :accepts_nested_attributes_for, :abstractor_object_value_variants, allow_destroy: true

          base.send(:include, InstanceMethods)
          base.extend(ClassMethods)
        end

        # Instance Methods
        module InstanceMethods
          def used?
            @used = @used || (self.abstractor_suggestions.any? || self.abstractor_abstractions.any?)
          end

          def object_variants
            [value].concat(abstractor_object_value_variants.map(&:value))
          end

          def update_abstractor_abstraction_schema_object_values
            self.abstractor_abstraction_schema_object_values.reject(&:new_record?).map(&:touch)
          end

          def set_soft_delete_abstractor_object_value_variants
            self.abstractor_object_value_variants.select(&:marked_for_destruction?).map(&:process_soft_delete)
          end

          def soft_delete_abstractor_suggestions
            if self.deleted_at.present? && self.deleted_at_changed?
              as = self.abstractor_suggestions.not_deleted.where('accepted IS NULL OR accepted = ?', false)
              as.each(&:soft_delete!)
              as.each do |abstractor_suggestion|
                if abstractor_suggestion.abstractor_abstraction.abstractor_suggestions.not_deleted.empty?
                  abstractor_abstraction = abstractor_suggestion.abstractor_abstraction
                  abstractor_abstraction_source = abstractor_abstraction.abstractor_subject.abstractor_abstraction_sources.first
                  abstractor_suggestion.abstractor_abstraction.abstractor_subject.create_unknown_abstractor_suggestion(abstractor_abstraction.about, abstractor_abstraction, abstractor_abstraction_source)
                end
              end
            end
          end

          def soft_delete_abstractor_object_value_variants
            if self.deleted_at.present? && self.deleted_at_changed?
              self.abstractor_object_value_variants.not_deleted.map(&:soft_delete!)
            end
          end
        end

        # Class Methods
        module ClassMethods
          def search_across_fields(search_token, options={})
            if search_token
              search_token.downcase!
            end
            options = { sort_column: 'value', sort_direction: 'asc' }.merge(options)

            if search_token
              s = where("LOWER(value) LIKE ? OR LOWER(vocabulary) LIKE ? OR LOWER(vocabulary_version) LIKE ? OR LOWER(vocabulary_code) LIKE ?", *Array.new(4, "%#{search_token}%"))
            end

            sort = options[:sort_column] + ' ' + options[:sort_direction] + ', abstractor_object_values.id ASC'
            s = s.nil? ? order(sort) : s.order(sort)
          end
        end
      end
    end
  end
end