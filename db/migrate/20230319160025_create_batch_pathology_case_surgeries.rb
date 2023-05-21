class CreateBatchPathologyCaseSurgeries < ActiveRecord::Migration[5.2]
  def change
    create_table :batch_pathology_case_surgeries do |t|
      t.string  :west_mrn, null: true
      t.string  :source_system, null: true
      t.string  :stable_identifier_path, null: true
      t.string  :stable_identiifer_value, null: true
      t.string  :case_collect_datetime, null: true
      t.string  :accessioned_datetime, null: true
      t.string  :accession_nbr_formatted, null: true
      t.string  :group_name, null: true
      t.string  :group_desc, null: true
      t.string  :group_id, null: true
      t.string  :snomed_code, null: true
      t.string  :snomed_name, null: true
      t.string  :responsible_pathologist_full_name, null: true
      t.string  :responsible_pathologist_npi, null: true
      t.string  :section_description, null: true
      # t.string  :note_text, null: true
      t.string  :surgical_case_number, null: true
      t.string  :surgery_name, null: true
      t.string  :surgery_start_date, null: true
      t.string  :code_type, null: true
      t.string  :cpt_code, null: true
      t.string  :cpt_name, null: true
      t.string  :primary_surgeon_full_name, null: true
      t.string  :primary_surgeon_npi, null: true
      t.string  :row_id, null: true
      t.timestamps
    end
  end
end
