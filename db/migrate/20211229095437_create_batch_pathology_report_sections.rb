class CreateBatchPathologyReportSections < ActiveRecord::Migration[5.2]
  def change
    create_table :batch_pathology_report_sections do |t|
      t.string  :west_mrn, null: true
      t.string  :source_system, null: true
      t.string  :stable_identifier_path, null: true
      t.string  :stable_identifier_value, null: true
      t.string  :accession_nbr_formatted, null: true
      t.string  :accessioned_datetime, null: true
      t.string  :present_map_count, null: true
      t.string  :surgical_case_key, null: true
      t.string  :or_case_id, null: true
      t.string  :surg_case_id, null: true
      t.string  :cpt, null: true
      t.string  :cpt_description, null: true
      t.string  :surgery_name, null: true
      t.string  :group_name, null: true
      t.string  :group_desc, null: true
      t.string  :snomed_code, null: true
      t.string  :snomed_name, null: true
      t.string  :group_id, null: true
      t.string  :responsible_pathologist_full_name, null: true
      t.string  :responsible_pathologist_npi, null: true
      t.string  :primary_surgeon_full_name, null: true
      t.string  :primary_surgeon_npi, null: true
      t.string  :section_description, null: true
      t.text    :note_text, null: true
      t.timestamps
    end
  end
end


