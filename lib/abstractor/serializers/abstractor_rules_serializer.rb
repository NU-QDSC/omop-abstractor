require 'json'
module Abstractor
  module Serializers
    class AbstractorRulesSerializer
      def initialize(abstractor_rules)
        @abstractor_rules = abstractor_rules
      end

      def as_json(options = {})
        json = {}
        json['abstractor_rules'] = []
        @abstractor_rules.each do |abstractor_rule|
          ar = {}
          ar['rule'] = abstractor_rule.rule
          ar['abstractor_abstraction_schemas'] = []
          abstractor_rule.abstractor_rule_abstractor_subjects.each do |abstractor_rule_abstractor_subject|
            abstractor_abstraction_schema = {
              'predicate' => abstractor_rule_abstractor_subject.abstractor_subject.abstractor_abstraction_schema.predicate,
              'display_name' => abstractor_rule_abstractor_subject.abstractor_subject.abstractor_abstraction_schema.display_name,
              'abstractor_abstraction_schema_id' => abstractor_rule_abstractor_subject.abstractor_subject.abstractor_abstraction_schema.id,
              'abstractor_subject_id' => abstractor_rule_abstractor_subject.abstractor_subject.id
            }
            ar['abstractor_abstraction_schemas'] << abstractor_abstraction_schema
          end
          json['abstractor_rules'] << ar
        end
        json
      end

      private

        attr_reader :abstractor_rules
    end
  end
end