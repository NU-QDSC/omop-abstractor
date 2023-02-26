module Abstractor
  module Methods
    module Models
      module AbstractorAbstractionGroup
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_subject_group
          base.send :belongs_to, :about, polymorphic: true

          base.send :has_many, :abstractor_abstraction_group_members
          base.send :has_many, :abstractor_abstractions, :through => :abstractor_abstraction_group_members

          # base.send :attr_accessible, :abstractor_subject_group, :abstractor_subject_group_id, :deleted_at, :about, :about_type, :about_id

          # Hooks
          base.send :validate, :validate_subject_group_cardinality
          base.send :validate, :must_have_members

          base.send :after_commit, :update_abstractor_abstraction_group_members, :on => :update, :if => Proc.new { |record| record.previous_changes.include?('deleted_at') }

          base.send(:include, InstanceMethods)
          base.extend(ClassMethods)
        end

        module InstanceMethods
          ##
          # Determines if the group can be removed.
          #
          # @return [Boolean]
          def removable?
            !system_generated
          end

          def has_subtype?(s)
            subtype == s
          end

          ##
          # Whether or not is fully set: all of its abstrations have a vlue set.
          #
          # @return [Boolean]
          def fully_set?
            !abstractor_abstractions.not_deleted.any? { |abstractor_abstraction| abstractor_abstraction.value.blank?  }
          end

          ##
          # Whether or not it has a 'discarded' workflow status.
          #
          # @return [Boolean]
          def discarded?
            !abstractor_abstractions.not_deleted.any? { |abstractor_abstraction| !abstractor_abstraction.discarded? }
          end

          ##
          # Whether or not it has 'submitted' workflow status.
          #
          # @return [Boolean]
          def submitted?
            !abstractor_abstractions.not_deleted.any? { |abstractor_abstraction| !abstractor_abstraction.submitted? }
          end

          ##
          # A calculation across the abstraction group's abstractions' workflow statuses.
          #
          # @return [String]
          def workflow_status
            (Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUSES & abstractor_abstractions.not_deleted.map(&:workflow_status).uniq)
          end

          ##
          # Whether or not it should be considered 'read only'
          #
          # @return [Boolean]
          def read_only?
            !(workflow_status.join == Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
          end
          
          def anchor?            
            anchor.present?
          end

          def anchor
            abstractor_abstraction_group_members.not_deleted.detect { |abstractor_abstraction_group_member| abstractor_abstraction_group_member.abstractor_abstraction.abstractor_subject.anchor }
          end

          private
            def update_abstractor_abstraction_group_members
              return unless deleted?
              abstractor_abstraction_group_members.each do |gm|
                gm.soft_delete!
                gm.abstractor_abstraction.soft_delete!
              end
            end

            def must_have_members
              if self.abstractor_abstraction_group_members.empty? || self.abstractor_abstraction_group_members.all? {|abstractor_abstraction_group_member| abstractor_abstraction_group_member.marked_for_destruction? }
                errors.add(:base, 'Must have at least one abstractor_abstraction_group_member')
              end
            end

            def validate_subject_group_cardinality
              return if self.abstractor_subject_group.cardinality.blank? || self.persisted?
              errors.add(:base,"Subject group reached maximum number of abstraction groups (#{abstractor_subject_group.cardinality})") if self.about.abstractor_subject_group_complete?(self.abstractor_subject_group_id)
            end
        end
        module ClassMethods
          ##
          # Creates an abstraction group with the given paramaters.
          #
          # @param [Integer] abstractor_subject_group_id identifier of subject group to create.
          # @param [String] about_type type of abstractable entity to create the abstraction group.
          # @param [Integer] about_id identifier of abstractable entity to create the abstraction group.
          # @option options [String] :namespace_type The type parameter of the namespace.
          # @option options [Integer] :namespace_id The instance parameter of the namespace.
          # @return [Abstractor::] List of [Abstractor::AbstractorAbstraction].
          def create_abstractor_abstraction_group(abstractor_subject_group_id, about_type, about_id, namespace_type, namespace_id)
            abstractor_abstraction_group = Abstractor::AbstractorAbstractionGroup.new(abstractor_subject_group_id: abstractor_subject_group_id, about_type: about_type, about_id: about_id)
            abstractor_subjects = abstractor_abstraction_group.abstractor_subject_group.abstractor_subjects
            unless namespace_type.blank? || namespace_id.blank?
              abstractor_subjects = abstractor_subjects.where(namespace_type: namespace_type, namespace_id: namespace_id)
            end

            abstractor_subjects.each do |abstractor_subject|
              abstraction = abstractor_subject.abstractor_abstractions.build(about_id: about_id, about_type: about_type, workflow_status: Abstractor::Enum::ABSTRACTION_WORKFLOW_STATUS_PENDING)
              abstractor_subject.abstractor_abstractions.where(about_id: about_id, about_type: about_type).each do |abstractor_abstraction|
                if !abstractor_abstraction.abstractor_abstraction_group.removable?
                  abstractor_abstraction.abstractor_suggestions.each do |abstractor_suggestion|
                    suggestion_sources = []
                    abstractor_suggestion.abstractor_suggestion_sources.each do |abstractor_suggestion_source|
                      suggestion_sources << Abstractor::AbstractorSuggestionSource.new(match_value: abstractor_suggestion_source.match_value, sentence_match_value: abstractor_suggestion_source.sentence_match_value, source_id: abstractor_suggestion_source.source_id, source_method: abstractor_suggestion_source.source_method, source_type: abstractor_suggestion_source.source_type, custom_method: abstractor_suggestion_source.custom_method, custom_explanation: abstractor_suggestion_source.custom_explanation, section_name: abstractor_suggestion_source.section_name)
                    end

                    abstraction.abstractor_suggestions.build(suggested_value: abstractor_suggestion.suggested_value, unknown: abstractor_suggestion.unknown, not_applicable: abstractor_suggestion.not_applicable, accepted: nil, abstractor_object_value: abstractor_suggestion.abstractor_object_value, abstractor_suggestion_sources: suggestion_sources)
                  end
                end
              end

              abstraction.abstractor_subject.abstractor_abstraction_sources.select { |s| s.abstractor_abstraction_source_type.name == 'indirect' }.each do |abstractor_abstraction_source|
                source = abstractor_subject.subject_type.constantize.find(about_id).send(abstractor_abstraction_source.from_method)
                abstraction.abstractor_indirect_sources.build(abstractor_abstraction_source: abstractor_abstraction_source, source_type: source[:source_type], source_method: source[:source_method])
              end
              abstractor_abstraction_group.abstractor_abstractions << abstraction
            end
            abstractor_abstraction_group.save!
            abstractor_abstraction_group
          end
        end
      end
    end
  end
end
