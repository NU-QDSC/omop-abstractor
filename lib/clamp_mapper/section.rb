module ClampMapper
  class Section
    attr_accessor :document, :section_begin, :section_end, :name, :named_entity
    def initialize(document, section_begin, section_end)
      @document = document
      @section_begin = section_begin.to_i
      @section_end = section_end.to_i
      @named_entity = document.section_named_entities.detect { |section_named_entity| section_named_entity.named_entity_begin >= @section_begin  && section_named_entity.named_entity_end <= @section_end }
      if @named_entity
        @name = @named_entity.semantic_tag
      else
        @name = nil
      end
    end

    def ==(other)
      self.section_begin == other.section_begin && self.section_end == other.section_end
    end

    def section_range
      @section_begin..@section_end
    end

    def to_s
      named_entity.to_s
    end

    def trigger
      to_s[to_s.length-2]
    end
  end
end