require './lib/clamp_mapper/parser'
module ClampMapper
  def self.map_to_abstractor(file)
    parser = ClampMapper::Parser.new
    parser.read(file)
  end
end

#
# parser.document.xmi_document
# parser.document.name
# parser.document.text
#
# parser.document.sections.size
# parser.document.sections[0]
# parser.document.sections[0].section_begin
# parser.document.sections[0].section_end
# parser.document.sections[0].section_names.size
# parser.document.sections[0].section_names.each do |section_name|
#   puts section_name
# end
#
# parser.document.sentences.size
# parser.document.sentences[0]
# parser.document.sentences[0].sentence_begin
# parser.document.sentences[0].sentence_end
# parser.document.sentences[0].sentence_number
# parser.document.sentences[0].section
#
# parser.document.named_entities.size
# parser.document.named_entities[0]
# parser.document.named_entities[0].named_entity_begin
# parser.document.named_entities[0].named_entity_end
# parser.document.named_entities[0].semantic_tag
# parser.document.named_entities[0].assertion
