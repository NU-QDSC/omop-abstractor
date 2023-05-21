require './lib/abstractor/setup'
require './lib/abstractor/abstractable'
require './lib/abstractor/custom_nlp_provider'
require './lib/abstractor/enum'
require './lib/abstractor/negation_detection'
require './lib/abstractor/parser'
require './lib/abstractor/user_interface'
require './lib/abstractor/utility'
require './lib/abstractor/core_ext/string'
require './lib/abstractor/methods/controllers/abstractor_abstraction_groups_controller'
require './lib/abstractor/methods/controllers/abstractor_abstraction_schemas_controller'
require './lib/abstractor/methods/controllers/abstractor_abstractions_controller'
require './lib/abstractor/methods/controllers/abstractor_object_values_controller'
require './lib/abstractor/methods/controllers/abstractor_object_value_variants_controller'
require './lib/abstractor/methods/controllers/abstractor_rules_controller'
require './lib/abstractor/methods/controllers/abstractor_suggestions_controller'
require './lib/abstractor/methods/models/abstractor_abstraction_group_member'
require './lib/abstractor/methods/models/abstractor_abstraction_group'
require './lib/abstractor/methods/models/abstractor_abstraction_object_value'
require './lib/abstractor/methods/models/abstractor_abstraction_schema_object_value'
require './lib/abstractor/methods/models/abstractor_abstraction_schema_predicate_variant'
require './lib/abstractor/methods/models/abstractor_abstraction_schema_relation'
require './lib/abstractor/methods/models/abstractor_abstraction_schema'
require './lib/abstractor/methods/models/abstractor_abstraction_source_type'
require './lib/abstractor/methods/models/abstractor_abstraction_source'
require './lib/abstractor/methods/models/abstractor_abstraction'
require './lib/abstractor/methods/models/abstractor_indirect_source'
require './lib/abstractor/methods/models/abstractor_object_type'
require './lib/abstractor/methods/models/abstractor_object_value_variant'
require './lib/abstractor/methods/models/abstractor_object_value'
require './lib/abstractor/methods/models/abstractor_relation_type'
require './lib/abstractor/methods/models/abstractor_rule_abstractor_subject'
require './lib/abstractor/methods/models/abstractor_rule_type'
require './lib/abstractor/methods/models/abstractor_rule'
require './lib/abstractor/methods/models/abstractor_section_name_variant'
require './lib/abstractor/methods/models/abstractor_section_type'
require './lib/abstractor/methods/models/abstractor_section'
require './lib/abstractor/methods/models/abstractor_section_mention_type'
require './lib/abstractor/methods/models/abstractor_subject_group_member'
require './lib/abstractor/methods/models/abstractor_subject_group'
require './lib/abstractor/methods/models/abstractor_subject_relation'
require './lib/abstractor/methods/models/abstractor_subject'
require './lib/abstractor/methods/models/abstractor_suggestion_object_value_variant'
require './lib/abstractor/methods/models/abstractor_suggestion_object_value'
require './lib/abstractor/methods/models/abstractor_suggestion_source'
require './lib/abstractor/methods/models/abstractor_suggestion_status'
require './lib/abstractor/methods/models/abstractor_suggestion'
require './lib/abstractor/methods/models/soft_delete'
require './lib/abstractor/methods/models/abstractor_abstraction_source_section'
require './lib/abstractor/serializers/abstractor_abstraction_schema_serializer'
require './lib/abstractor/serializers/abstractor_rules_serializer'

ENV['CLASSPATH'] = "$CLASSPATH:#{File.expand_path('../..', __FILE__)}/lingscope/dist/lingscope.jar:#{File.expand_path('../..', __FILE__)}/lingscope/dist/lib/abner.jar"
module Abstractor
  def self.table_name_prefix
    ''
  end
end