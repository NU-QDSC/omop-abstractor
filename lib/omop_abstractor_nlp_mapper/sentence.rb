module OmopAbstractorNlpMapper
  class Sentence
    attr_accessor :document, :sentence_begin, :sentence_end, :sentence_number, :section
    def initialize(document, sentence_begin, sentence_end, sentence_number)
      @document = document
      @sentence_begin = sentence_begin.to_i
      @sentence_end = sentence_end.to_i
      @sentence_number = sentence_number.to_i
    end

    def section
      @section = @document.sections.detect do |section|
       section_preamble = section.begin_header
       look = true
       while look
         section_preamble = section_preamble - 1
         if section_preamble == 0 || @document.text[section_preamble] == "\n"
           look = false
         end
       end

        @sentence_begin >= section_preamble  && @sentence_end <= section.section_end
      end
    end

    def to_s
      @document.text[sentence_begin..sentence_end]
    end
  end
end