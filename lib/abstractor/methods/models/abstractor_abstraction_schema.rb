module Abstractor
  module Methods
    module Models
      module AbstractorAbstractionSchema
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_object_type
          base.send :has_many, :abstractor_subjects
          base.send :has_many, :abstractor_abstraction_schema_predicate_variants
          base.send :has_many, :abstractor_abstraction_schema_object_values
          base.send :has_many, :abstractor_object_values, :through => :abstractor_abstraction_schema_object_values
          base.send :has_many, :object_relations,   :class_name => "Abstractor::AbstractorAbstractionSchemaRelation", :foreign_key => "object_id"
          base.send :has_many, :subject_relations,  :class_name => "Abstractor::AbstractorAbstractionSchemaRelation", :foreign_key => "subject_id"

          base.send(:include, InstanceMethods)
          base.extend(ClassMethods)
        end

        # Instance Methods
        module InstanceMethods
          ##
          # All of the different ways of referring to the predicate.
          #
          # @return [Array<String>]
          def predicate_variants
            [preferred_name].concat(abstractor_abstraction_schema_predicate_variants.map(&:value))
          end

          ##
          # Whether or not it is a list.
          #
          # @return [Boolean]
          def object_type_list?
            case abstractor_object_type.value
            when Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_LIST, Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_RADIO_BUTTON_LIST
              true
            else
              false
            end
          end

          ##
          # Whether or not it is a postive/negative list.
          #
          # @return [Boolean]
          def positive_negative_object_type_list?
            abstractor_object_values.map(&:value).sort == ['negative', 'positive']
          end

          ##
          # Whether or not it is a deleted/non-deleted list.
          #
          # @return [Boolean]
          def deleted_non_deleted_object_type_list?
            abstractor_object_values.map(&:value).sort == ['deleted', 'non-deleted']
          end

          ##
          # Whether or not it is a present/not identified list.
          #
          # @return [Boolean]
          def present_not_identified_object_type_list?
            abstractor_object_values.map(&:value).sort == ['not identified', 'present']
          end
        end

        # Class Methods
        module ClassMethods
          def search_across_fields(search_token, options={})
            if search_token
              search_token.downcase!
            end
            options = { sort_column: 'display_name', sort_direction: 'asc' }.merge(options)

            if search_token
              s = where("LOWER(predicate) LIKE ? OR LOWER(display_name) LIKE ? OR LOWER(preferred_name) LIKE ?", *Array.new(3, "%#{search_token}%"))
            end

            sort = options[:sort_column] + ' ' + options[:sort_direction] + ', abstractor_abstraction_schemas.id ASC'
            s = s.nil? ? order(sort) : s.order(sort)
          end
        end
      end
    end
  end
end