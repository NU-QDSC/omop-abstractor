module ClampMapper
  class NamedEntity
    attr_accessor :document, :named_entity_begin, :named_entity_end, :semantic_tag, :semantic_tag_attribute, :semantic_tag_value, :semantic_tag_value_type, :assertion, :is_section, :sentence

    def initialize(document, named_entity_begin, named_entity_end, semantic_tag, assertion, is_section)
      @document = document
      @named_entity_begin = named_entity_begin.to_i
      @named_entity_end = named_entity_end.to_i
      @semantic_tag = semantic_tag
      @semantic_tag_attribute, @semantic_tag_value = semantic_tag.split('|')
      @semantic_tag_attribute, @semantic_tag_value_type = @semantic_tag_attribute.split(':')
      if @semantic_tag_attribute == 'number'
        @semantic_tag_value = @document.text[@named_entity_begin...@named_entity_end]
      end

      if @semantic_tag_attribute == 'temporal'
        @semantic_tag_value = @document.text[@named_entity_begin...@named_entity_end]
      end

      @assertion = assertion
      @is_section = is_section
      @sentence = document.sentences.detect { |sentence| @named_entity_begin >= sentence.sentence_begin  && @named_entity_end <= sentence.sentence_end  }
    end

    def negated?
      @assertion == 'absent'
    end

    def overlap?(other)
      other.named_entity_begin >= self.named_entity_begin  && other.named_entity_begin <= self.named_entity_end && other.named_entity_end >= self.named_entity_begin && other.named_entity_end <= self.named_entity_end
    end

    def to_s
      document.text[self.named_entity_begin...self.named_entity_end]
    end

    def named_entity_range
      @named_entity_begin..@named_entity_end
    end
  end
end