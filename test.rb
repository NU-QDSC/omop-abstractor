require 'nokogiri'
file_path = "#{Rails.root}/lib/setup/data/ohdsi_nlp_proposal/Pathology Cases with Surgeries V2 All.xml"
xml_data = File.read(file_path)
doc = Nokogiri::XML(xml_data)

# Assuming there's a <name> tag within the XML
name = doc.at_xpath('//name').text
puts "Name: #{name}"


# Assuming there are multiple <item> tags within the XML
doc.xpath('//item').each do |item|
  # Access element attributes
  id = item['id']
  # Access element text value
  value = item.text
  puts "ID: #{id}, Value: #{value}"
end


# Find all <product> tags that have a price greater than 100
products = doc.xpath('//product[price > 100]')
products.each do |product|
  # Access element values within the matched <product> tags
  name = product.at_xpath('name').text
  price = product.at_xpath('price').text
  puts "Product: #{name}, Price: #{price}"
end


#streaming

require 'nokogiri'

file_path = "#{Rails.root}/lib/setup/data/ohdsi_nlp_proposal/Pathology Cases with Surgeries V2 All test.xml"

# Open the XML file for streaming
File.open(file_path) do |file|
  # Create a Nokogiri XML parser with the file stream
  parser = Nokogiri::XML::SAX::Parser.new(MyHandler.new)

  # Parse the XML file node by node
  parser.parse(file)
end

# Define your own SAX handler class by inheriting from Nokogiri's SAX::Document class
class MyHandler < Nokogiri::XML::SAX::Document

  def initialize
    @current_element = nil
  end

  # Callback method triggered when an element starts
  def start_element(name, attrs = [])
    @current_element = name
    puts "Start element: #{name}"

    # Access element attributes if needed
    attrs.each do |attr|
      puts "Attribute: #{attr}"
    end
  end

  # Callback method triggered when an element ends
  def end_element(name)
    @current_element = nil
    puts "End element: #{name}"
  end

  # Callback method triggered when text content is encountered within an element
  def characters(string)
    # Only handle text content if it is within a specific element
    puts "Name: #{string}"
    # puts 'hello'
    # if @current_element == 'snomed_code'
    #   puts "Name: #{string}"
    # end
  end
end