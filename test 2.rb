require 'nokogiri'

file_path = "#{Rails.root}/lib/setup/data/ohdsi_nlp_proposal/Pathology Cases with Surgeries V2 All test.xml"
pathology_case_handler = Omop::PathologyCaseHandler.new
File.open(file_path) do |file|
  parser = Nokogiri::XML::SAX::Parser.new(pathology_case_handler)
  parser.parse(file)
end

# puts pathology_case_handler.pathology_cases.size

pathology_case = Omop::PathologyCase.new
pathology_case.fields