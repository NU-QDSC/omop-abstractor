require './lib/omop_abstractor_nlp_mapper/section'
require './lib/omop_abstractor_nlp_mapper/sentence'
require './lib/omop_abstractor_nlp_mapper/named_entity'
module OmopAbstractorNlpMapper
  class Document
    attr_accessor :document, :text, :sections, :sentences, :named_entities, :namespace_type, :namespace_id
    def initialize(document, text)
      @document = document
      @text = text
      @namespace_type = document[:namespace_type]
      @namespace_id = document[:namespace_id]

      @sentences = []
      document[:sentences].each do |sentence|
        @sentences << OmopAbstractorNlpMapper::Sentence.new(self, sentence[:begin], sentence[:end], sentence[:sentence_number])
      end

      # puts 'how many sentences?'
      # puts @sentences.length

      @named_entities = []
      document[:abstractor_suggestions].each do |named_entity|
        is_section = false
        @named_entities << OmopAbstractorNlpMapper::NamedEntity.new(self, named_entity[:begin], named_entity[:end], named_entity[:predicate], named_entity[:value], named_entity[:type], named_entity[:assertion], is_section)
        # puts 'here is the named entity'
        # if @named_entities.last.sentence
        #   puts @named_entities.last.sentence
        #   puts @named_entities.last.sentence.sentence_begin
        #   puts @named_entities.last.sentence.sentence_end
        # else
        #   puts 'no sentence'
        # end
        # puts @named_entities.last.named_entity_begin
        # puts @named_entities.last.named_entity_end
        # puts @named_entities.last.semantic_tag_attribute
        # puts @named_entities.last.semantic_tag_value
        # puts @named_entities.last.semantic_tag_value_type
        # puts @named_entities.last.assertion
        # puts @named_entities.last.is_section
      end

      # puts 'how many times named entities?'
      # puts @named_entities.length

      document[:sections].each do |named_entity|
        is_section = true
        @named_entities << OmopAbstractorNlpMapper::NamedEntity.new(self, named_entity[:begin], named_entity[:end], named_entity[:section_name], nil, nil, 'present', is_section)
      end

      @sections = []

      # puts 'little my talks about sections 1'
      # puts "document[:sections].length"
      # puts document[:sections].length
      document[:sections].each do |section|
        @sections << OmopAbstractorNlpMapper::Section.new(self, section[:begin], section[:end], section[:begin_header], section[:end_header])
      end

      # puts 'little my talks about sections 2'
      # puts "@sections.length"
      # puts @sections.length


      # puts 'little my talks about sections 3'
      # puts "@sections.length"
      # puts @sections.length
      @sections.reject! { |section| section.name.nil? }
    end

    def named_entities
      @named_entities.select { |named_entity| !named_entity.is_section }
    end

    def section_named_entities
      @named_entities.select { |named_entity| named_entity.is_section }
    end

    def add_named_entity(named_entity_begin, named_entity_end, semantic_tag_attribute, semantic_tag_value, semantic_tag_value_type, assertion, is_section, section_begin_header, section_end_header)
      @named_entities << OmopAbstractorNlpMapper::NamedEntity.new(self, named_entity_begin, named_entity_end, semantic_tag_attribute, semantic_tag_value, semantic_tag_value_type, assertion, is_section)
      if is_section
        @sections << OmopAbstractorNlpMapper::Section.new(self, named_entity_begin, named_entity_end, section_begin_header, section_end_header)
      end
    end
  end
end