class CreateBatchNuChersPathologyReportSections < ActiveRecord::Migration[5.2]
  def change
    create_table :batch_nu_chers_pathology_report_sections do |t|
      t.string  :west_mrn
      t.string  :source_system
      t.string  :stable_identifier_path
      t.string  :stable_identiifer_value
      t.string  :case_collect_datetime
      t.string  :accessioned_datetime
      t.string  :accession_nbr_formatted
      t.string  :group_name
      t.string  :group_desc
      t.string  :group_id
      t.string  :snomed_code
      t.string  :snomed_name
      t.string  :responsible_pathologist_full_name
      t.string  :responsible_pathologist_npi
      t.string  :section_description
      t.text    :note_text
      t.string  :surgical_case_number
      t.string  :surgery_name
      t.string  :surgery_start_date
      t.string  :code_type
      t.string  :cpt_code
      t.string  :cpt_name
      t.string  :primary_surgeon_full_name
      t.string  :primary_surgeon_npi
      t.string  :case_num
      t.timestamps
    end
  end
end

# west_mrn
# source_system
# stable_identifier_path
# stable_identiifer_value
# case_collect_datetime
# accessioned_datetime
# accession_nbr_formatted
# group_name
# group_desc
# group_id
# snomed_code
# snomed_name
# responsible_pathologist_full_name
# responsible_pathologist_npi
# section_description
# note_text
# surgical_case_number
# surgery_name
# surgery_start_date
# code_type
# cpt_code
# cpt_name
# primary_surgeon_full_name
# primary_surgeon_npi
# case_num

# west mrn
# source system
# stable identifier path
# stable identiifer value
# case collect datetime
# accessioned datetime
# accession nbr formatted
# group name
# group desc
# group id
# snomed code
# snomed name
# responsible pathologist full name
# responsible pathologist npi
# section description
# note text
# surgical case number
# surgery name
# surgery start date
# code type
# cpt code
# cpt name
# primary surgeon full name
# primary surgeon npi
# case num