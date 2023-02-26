module OmopAbstractorClampDictionaryExporter
  def self.create_name_dictionary_items(abstractor_abstraction_schema)
    dictionary_items = []
    puts abstractor_abstraction_schema.predicate
    abstractor_abstraction_schema.predicate_variants.each do |predicate_variant|
      predicate_variant.gsub!(',', ' , ')
      predicate_variant.gsub!('-', ' - ')
      puts 'in name add'
      dictionary_items << "#{predicate_variant}\t#{abstractor_abstraction_schema.predicate}:Name|#{predicate_variant}"
    end
    puts 'name length'
    puts dictionary_items.length
    dictionary_items
  end

  # ABSTRACTOR_OBJECT_TYPE_LIST                 = 'list'
  # ABSTRACTOR_OBJECT_TYPE_NUMBER               = 'number'
  # ABSTRACTOR_OBJECT_TYPE_BOOLEAN              = 'boolean'
  # ABSTRACTOR_OBJECT_TYPE_STRING               = 'string'
  # ABSTRACTOR_OBJECT_TYPE_RADIO_BUTTON_LIST    = 'radio button list'
  # ABSTRACTOR_OBJECT_TYPE_DATE                 = 'date'
  # ABSTRACTOR_OBJECT_TYPE_DYNAMIC_LIST         = 'dynamic list'
  # ABSTRACTOR_OBJECT_TYPE_TEXT                 = 'text'
  # ABSTRACTOR_OBJECT_TYPE_NUMBER_LIST          = 'number list'

  def self.create_value_dictionary_items(abstractor_abstraction_schema)
    dictionary_items = []
    case abstractor_abstraction_schema.abstractor_object_type.value
    when Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_LIST, Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_RADIO_BUTTON_LIST, Abstractor::Enum::ABSTRACTOR_OBJECT_TYPE_NUMBER_LIST
      puts abstractor_abstraction_schema.predicate
      abstractor_abstraction_schema.abstractor_object_values.each do |abstractor_object_value|
        abstractor_object_value.object_variants.each do |object_variant|
          object_variant.gsub!(',', ' , ')
          object_variant.gsub!('-', ' - ')
          puts 'in value add'
          dictionary_items << "#{object_variant}\t#{abstractor_abstraction_schema.predicate}:Value|#{abstractor_object_value.value}"
        end
      end
    end
    puts 'value length'
    puts dictionary_items.length
    dictionary_items
  end
end