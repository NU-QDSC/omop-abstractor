module Omop
  # Define your own SAX handler class by inheriting from Nokogiri's SAX::Document class
  class PathologyCaseHandler < Nokogiri::XML::SAX::Document
    attr_accessor :pathology_cases
    def initialize
      @current_element = nil
      @pathology_cases = []
      @current_pathology_case = nil
    end

    # Callback method triggered when an element starts
    def start_element(name, attrs = [])
      @current_element = name
      if name == 'Detail'
        @current_pathology_case = Omop::PathologyCase.new
      end
      @characters = ""
    end

    # Callback method triggered when an element ends
    def end_element(name)
      if name == 'Detail'
        @pathology_cases << @current_pathology_case
      end
      @current_element = nil
    end

    # Callback method triggered when text content is encountered within an element
    def characters(string)
      if @current_pathology_case && @current_pathology_case.fields.include?(@current_element.to_sym)
        @characters += string
        @current_pathology_case.instance_variable_set("@#{@current_element}", @characters)
      end
    end
  end
end