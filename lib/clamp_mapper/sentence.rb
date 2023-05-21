module ClampMapper
  class Sentence
    attr_accessor :document, :sentence_begin, :sentence_end, :sentence_number, :section
    def initialize(document, sentence_begin, sentence_end, sentence_number)
      @document = document
      @sentence_begin = sentence_begin.to_i
      @sentence_end = sentence_end.to_i
      @sentence_number = sentence_number.to_i
    end

    def section
      @section = @document.sections.detect { |section| @sentence_begin >= section.section_begin  && @sentence_end <= section.section_end }
    end
  end
end