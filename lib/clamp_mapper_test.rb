require './lib/clamp_mapper/parser'
require './lib/clamp_mapper/process_note'

file = '/Users/mjg994/Documents/source/omop-abstractor/lib/setup/data_out/custom_nlp_provider_clamp/archive/NoteStableIdentifier_2267871_1638743025.json'
abstractor_note = ClampMapper::ProcessNote.process(JSON.parse(File.read(file)))
clamp_document = ClampMapper::Parser.new.read(abstractor_note)

puts clamp_document.named_entities.map { |named_entity| named_entity.semantic_tag_attribute }
named_entities = clamp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == abstractor_abstraction.abstractor_subject.abstractor_abstraction_schema.predicate }

named_entities = clamp_document.named_entities.select { |named_entity|  named_entity.semantic_tag_attribute == 'has_cancer_histology' }


named_entities.first.sentence
named_entities.each do |named_entity|
  # puts  named_entity.sentence
  # if clamp_document.text[named_entity.named_entity_begin..named_entity.named_entity_end] == 'Right'
    puts named_entity.sentence.section.present?
    puts clamp_document.text[named_entity.named_entity_begin..named_entity.named_entity_end]
    puts clamp_document.text[named_entity.sentence.sentence_begin..named_entity.sentence.sentence_end]
    # puts  named_entity.sentence.section
  # end
end