module Abstractor
  module Methods
    module Models
      module AbstractorSuggestion
        def self.included(base)
          base.send :include, SoftDelete

          # Associations
          base.send :belongs_to, :abstractor_abstraction

          base.send :has_one, :abstractor_suggestion_object_value, dependent: :destroy
          base.send :has_one, :abstractor_object_value, through: :abstractor_suggestion_object_value
          base.send :has_many, :abstractor_suggestion_object_value_variants, dependent: :destroy
          base.send :has_many, :abstractor_object_value_variants, through: :abstractor_suggestion_object_value_variants
          base.send :has_many, :abstractor_suggestion_sources, dependent: :destroy

          # Hooks
          base.send :after_save, :update_abstraction_value, if: Proc.new { |abstractor_suggestion| abstractor_suggestion.saved_change_to_attribute?(:accepted) }
          base.send :after_save, :update_siblings_status, if: Proc.new { |abstractor_suggestion| abstractor_suggestion.saved_change_to_attribute?(:accepted)  }
          base.send :after_create, :update_siblings_status, if: Proc.new { |abstractor_suggestion| abstractor_suggestion.accepted.nil? && abstractor_suggestion.abstractor_suggestion_object_value && !abstractor_suggestion.abstractor_suggestion_object_value.abstractor_object_value.favor_more_specific  }
        end

        # Instance Methods
        def update_abstraction_value
          abstractor_abstraction.reload
          if accepted
            abstractor_abstraction.value                     = suggested_value
            abstractor_abstraction.unknown                   = unknown
            abstractor_abstraction.not_applicable            = not_applicable
            abstractor_abstraction.save!
          elsif accepted.nil?
            abstractor_abstraction.value          = nil
            abstractor_abstraction.unknown        = nil
            abstractor_abstraction.not_applicable = nil
            abstractor_abstraction.save!
          elsif accepted == false
            abstractor_abstraction.value          = nil if abstractor_abstraction.value == suggested_value
            abstractor_abstraction.unknown        = nil if unknown && abstractor_abstraction.unknown == unknown
            abstractor_abstraction.not_applicable = nil if not_applicable && abstractor_abstraction.not_applicable == not_applicable
            abstractor_abstraction.save!
          end
        end

        def update_siblings_status
          if accepted
            #reject sibling suggestions
            self.sibling_suggestions.each do |abstractor_suggestion|
              abstractor_suggestion.accepted = false
              abstractor_suggestion.save!
            end
          elsif accepted.nil?
            #reset status on sibling suggestions
            self.sibling_suggestions.each do |abstractor_suggestion|
              abstractor_suggestion.accepted = nil
              abstractor_suggestion.save!
            end
            self.abstractor_abstraction.value = nil
            self.abstractor_abstraction.save!
          end
        end

        def display_value
          if unknown
            'unknown'
          elsif not_applicable
            'not applicable'
          else
            suggested_value
          end
        end

        def sibling_suggestions
          abstractor_abstraction.abstractor_suggestions.where('id != ?', id)
        end

        def detect_abstractor_suggestion_source(abstractor_abstraction_source, sentence_match_value, source_id, source_type, source_method, section_name)
          abstractor_suggestion_source = abstractor_suggestion_sources.detect do |abstractor_suggestion_source|
            abstractor_suggestion_source.abstractor_abstraction_source == abstractor_abstraction_source &&
            abstractor_suggestion_source.sentence_match_value == sentence_match_value &&
            abstractor_suggestion_source.source_id == source_id &&
            abstractor_suggestion_source.source_type == source_type &&
            abstractor_suggestion_source.source_method == source_method &&
            abstractor_suggestion_source.section_name == section_name
          end
        end

        def normalize_abstractor_suggestion_sentences
          normalization = []
          abstractor_suggestion_sources.map { |abstractor_suggestion_source| { source_type: abstractor_suggestion_source.source_type, source_method: abstractor_suggestion_source.source_method, source_id: abstractor_suggestion_source.source_id, section_name: abstractor_suggestion_source.section_name, sentences: [] } }.uniq.each do |source|
            suggestion_sources = abstractor_suggestion_sources.select { |abstractor_suggestion_source| abstractor_suggestion_source.source_type == source[:source_type] &&  abstractor_suggestion_source.source_method == source[:source_method] && abstractor_suggestion_source.source_id == source[:source_id] }
            suggestion_sources.map(&:sentence_match_value).compact.uniq.each do |sentence_match_value|
              match_values = suggestion_sources.select { |suggestion_source| suggestion_source.sentence_match_value == sentence_match_value }.map(&:match_value)
              non_overlapping_match_values = Abstractor::Utility.uniquify_overlapping_match_values(match_values)
              source[:sentences] << { sentence: sentence_match_value, match_values: non_overlapping_match_values }
            end
            normalization << source
          end
          normalization
        end
      end
    end
  end
end