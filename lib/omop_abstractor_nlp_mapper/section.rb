module OmopAbstractorNlpMapper
  class Section
    attr_accessor :document, :section_begin, :section_end, :name, :named_entity, :begin_header, :end_header

    def initialize(document, section_begin, section_end, begin_header, end_header)
      @document = document
      @section_begin = section_begin.to_i
      @section_end = section_end.to_i
      @named_entity = document.section_named_entities.detect { |section_named_entity| section_named_entity.named_entity_begin >= @section_begin  && section_named_entity.named_entity_end <= @section_end }
      @begin_header = begin_header
      @end_header = end_header

      if @named_entity
        @name = @named_entity.semantic_tag_attribute
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
      # to_s[to_s.length-2]
      # to_s[0]
      if @begin_header == @end_header
        document.text[@begin_header..@end_header].strip[-1]
      else
        document.text[@begin_header..@end_header].strip[-2]
      end
    end
  end
end