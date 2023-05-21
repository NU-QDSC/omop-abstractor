require './lib/clamp_mapper/section'
require './lib/clamp_mapper/sentence'
require './lib/clamp_mapper/named_entity'
module ClampMapper
  class Document
    attr_accessor :xmi_document, :name, :text, :sections, :sentences, :named_entities
    def initialize(document, name)
      @xmi_document = document
      @name = name
      @text = @xmi_document.xpath("//cas:Sofa")[0].attributes['sofaString'].value

      @sentences = []
      @xmi_document.xpath("//textspan:Sentence").each do |sentence|
        @sentences << ClampMapper::Sentence.new(self, sentence.attributes['begin'].value, sentence.attributes['end'].value, sentence.attributes['sentenceNumber'].value)
      end

      @named_entities = []
      @xmi_document.xpath("//typesystem:ClampNameEntityUIMA").each do |named_entity|
        is_section = nil
        if named_entity.attributes['attr2']
          is_section = true
        else
          is_section = false
        end
        @named_entities << ClampMapper::NamedEntity.new(self, named_entity.attributes['begin'].value, named_entity.attributes['end'].value, named_entity.attributes['semanticTag'].value, named_entity.attributes['assertion'].value, is_section)
      end

      @sections = []
      @xmi_document.xpath("//textspan:Segment").each do |section|
        @sections << ClampMapper::Section.new(self, section.attributes['begin'].value, section.attributes['end'].value)
      end

      @sections.reject! { |section| section.name.nil? }
    end

    def named_entities
      @named_entities.select { |named_entity| !named_entity.is_section }
    end

    def section_named_entities
      @named_entities.select { |named_entity| named_entity.is_section }
    end

    def add_named_entity(named_entity_begin, named_entity_end, semantic_tag, assertion, is_section)
      @named_entities << ClampMapper::NamedEntity.new(self, named_entity_begin, named_entity_end, semantic_tag, semantic_tag, is_section)
      if is_section
        @sections << ClampMapper::Section.new(self, named_entity_begin, named_entity_end)
      end
    end
  end
end