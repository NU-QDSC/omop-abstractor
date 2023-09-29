module Omop
  class PathologyCase
    attr_accessor :west_mrn
    attr_accessor :source_system
    attr_accessor :stable_identifier_path
    attr_accessor :stable_identifier_value
    attr_accessor :stable_identifier_value_1
    attr_accessor :stable_identifier_value_2
    attr_accessor :case_collect_datetime
    attr_accessor :accessioned_datetime
    attr_accessor :accession_nbr_formatted
    attr_accessor :group_name
    attr_accessor :group_desc
    attr_accessor :group_id
    attr_accessor :snomed_code
    attr_accessor :snomed_name
    attr_accessor :responsible_pathologist_full_name
    attr_accessor :responsible_pathologist_npi
    attr_accessor :section_description
    attr_accessor :note_text
    attr_accessor :surgical_case_number
    attr_accessor :surgery_name
    attr_accessor :surgery_start_date
    attr_accessor :code_type
    attr_accessor :cpt_code
    attr_accessor :cpt_name
    attr_accessor :primary_surgeon_full_name
    attr_accessor :primary_surgeon_npi

    def fields
      accessor_methods = self.methods - Object.methods - [:fields]
    end
  end
end