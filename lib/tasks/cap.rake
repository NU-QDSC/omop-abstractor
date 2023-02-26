# file = "lib/setup/data/nu_chers_cervical/Cervix.Trach.Hys.PlvEx.182_3.004.001.REL_sdcFDF.xml"
# document = File.open(file) { |f| Nokogiri::XML(f) }
# questions = document.css('FormDesign Body ChildItems Question')
# question = questions.detect { |q| q.attributes['title'].value == 'Ectocervical Margin'  }
# list_field = question.css('ListField').first
# list = question.css('List').first
# list.children.map(&:name)
# list.children.select { |child| child.name == 'ListItem'  }

# bundle exec rake cap:checklist_to_redcap
namespace :cap do
  desc 'Convert to REDCap'
  task(checklist_to_redcap: :environment) do |t, args|
    # file = "lib/setup/data/nu_chers/Cervix.Trach.Hys.PlvEx.182_3.004.001.REL_sdcFDF.xml"
    file = "lib/setup/data/nu_chers/Cervix.Cone.LEEP.183_2.007.001.REL_sdcFDF.xml"

    document = File.open(file) { |f| Nokogiri::XML(f) }
    # document.xpath("//FormDesign/Body/ChildItems/Question")
    redcap_variables = []
    document.css('FormDesign Body ChildItems Question').each do |question|
      variable_field_name = nil
      field_type = nil
      field_label = nil
      choices_calculations_or_slider_labels = []
      text_validation_type_or_show_slider_number = nil
      if question.attributes['title']        
        subquestions = question.css('Question').select{ |subquestion| subquestion.attributes['title'] && !(subquestion.attributes['title'].value =~ /Comments/i) }
        puts '--------------------------------'
        puts question.attributes['title']
        puts 'how many subquestions?'
        puts subquestions.size        
        if subquestions.size == 0
          puts 'no subquestions'
          field_label = question.attributes['title']
          list_field = question.css('ListField').first
          if list_field
            if list_field.attributes['maxSelections'].present?
              if list_field.attributes['maxSelections'].value == "0"
                field_type = 'checkbox'              
                list_items = list_field.css('ListItem')
                list_items.each do |list_item|
                  raw_value = list_item.attributes['ID'].value.split('.').first
                  choices_calculations_or_slider_labels << { raw_value: raw_value, label: list_item.attributes['title'] }
                end              
              end
              variable_field_name = field_label.to_s.parameterize(separator: "_")
              redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: choices_calculations_or_slider_labels }
            else
              field_type = 'radio'
              list_items = list_field.css('ListItem')            
              choices_calculations_or_slider_labels = []
              list_items.each do |list_item|
                decimal = list_item.css('decimal')
                if decimal.present?
                  field_type = 'text'
                  text_validation_type_or_show_slider_number = 'number'                
                  field_label = "#{question.attributes['title']}:#{list_item.attributes['title']}"
                  variable_field_name = field_label.to_s.parameterize(separator: "_")
                  redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: [] }
                else                  
                  raw_value = list_item.attributes['ID'].value.split('.').first
                  choices_calculations_or_slider_labels << { raw_value: raw_value, label: list_item.attributes['title'] }
                end
              end
              
              if choices_calculations_or_slider_labels.size == 1
                field_label = "#{question.attributes['title']}:#{choices_calculations_or_slider_labels.first}"                  
                text_validation_type_or_show_slider_number = nil                
                variable_field_name = field_label.to_s.parameterize(separator: "_")
                redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: [] }
              end
              if choices_calculations_or_slider_labels.size > 1
                text_validation_type_or_show_slider_number = nil                                
                variable_field_name = field_label.to_s.parameterize(separator: "_")
                redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: choices_calculations_or_slider_labels }              
              end
            end
          else
          end                
        else
          #subquestions          
          puts 'subquestions: yes'
          field_label = question.attributes['title']
          list_field = question.css('ListField').first
          if list_field
            if !list_field.attributes['maxSelections'].present?              
              list = question.css('List').first
              list.children.select { |child| child.name == 'ListItem'  }                          
              list_items = list_field.css('ListItem')                                      
              list_items.each do |list_item|
                decimal = list_item.css('decimal')
                if decimal.present?
                  field_type = 'text'
                  text_validation_type_or_show_slider_number = 'number'                
                  field_label = "#{question.attributes['title']}:#{list_item.attributes['title']}"
                  variable_field_name = field_label.to_s.parameterize(separator: "_")
                  redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: choices_calculations_or_slider_labels }
                else
                  field_type = 'radio'
                  field_label = "#{question.attributes['title']}:#{list_item.attributes['title']}"
                  text_validation_type_or_show_slider_number = nil                  
                  variable_field_name = field_label.to_s.parameterize(separator: "_")
                  redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: choices_calculations_or_slider_labels }                
                end
              end
            end                            
          end
          parent_field_label = question.attributes['title']          
          text_validation_type_or_show_slider_number = nil                    
          subquestions.each do |subquestion|
            text_validation_type_or_show_slider_number = nil
            field_label = "#{parent_field_label}:#{subquestion.attributes['title']}"
            decimal = subquestion.css('decimal')
            if decimal.present?
              field_type = 'text'
              text_validation_type_or_show_slider_number = 'number'                
              field_label = "#{field_label}"
              variable_field_name = field_label.to_s.parameterize(separator: "_")
              redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: choices_calculations_or_slider_labels }
            else
              # variable_field_name = field_label.to_s.parameterize(separator: "_")
              # redcap_variables << { variable_field_name: variable_field_name, field_label: field_label,  field_type: field_type, text_validation_type_or_show_slider_number: text_validation_type_or_show_slider_number, choices_calculations_or_slider_labels: choices_calculations_or_slider_labels }
            end          
          end
        end
      end
    end
    redcap_variables.each do |redcap_variable|
      puts '-------------------------------'
      puts "redcap_variable[:field_label]: #{redcap_variable[:field_label]}"                
      puts "redcap_variable[:variable_field_name]: #{redcap_variable[:variable_field_name]}"        
      puts "redcap_variable[:field_type]: #{redcap_variable[:field_type]}"                
      puts "redcap_variable[:text_validation_type_or_show_slider_number]: #{redcap_variable[:text_validation_type_or_show_slider_number]}"                
      if redcap_variable[:choices_calculations_or_slider_labels].any?
        puts 'begin choices_calculations_or_slider_label'
        redcap_variable[:choices_calculations_or_slider_labels].each do |choices_calculations_or_slider_label|
          puts "#{choices_calculations_or_slider_label[:raw_value]},#{choices_calculations_or_slider_label[:label]}"
        end
        puts 'end choices_calculations_or_slider_label'        
      end
    end      
  end
end