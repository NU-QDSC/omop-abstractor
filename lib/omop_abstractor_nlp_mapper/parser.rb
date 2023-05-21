require './lib/clamp_mapper/document'
module ClampMapper
  class Parser
    attr_accessor :document
    def read(abstractor_note)
      file_name = "#{abstractor_note['source_type']}_#{abstractor_note['source_id']}"
      @document = ClampMapper::Document.new(Nokogiri::XML(abstractor_note['clamp_xmi']), file_name)
    end
  end
end