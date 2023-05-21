class CreatePathologyAccessionNumbers < ActiveRecord::Migration[5.2]
  def change
    create_table :pathology_accession_numbers do |t|
      t.string  :case_number, null: true
      t.string  :specimen_identifier, null: true
      t.string  :specimen_type, null: true
      t.string  :specimen_type_normalized, null: true
      t.string  :collection_date_raw, null: true
      t.date    :collection_date, null: true
      t.string  :receive_date_raw, null: true
      t.date    :receive_date, null: true
      t.string  :source, null: true
      t.string  :accession_number_raw, null: true
      t.string  :raw_found, null: true
      t.string  :accession_number_normalized, null: true
      t.boolean :accession_number_found, null: true
      t.boolean :accession_number_case_number_found, null: true
      t.boolean :accession_number_case_number_collection_date_found, null: true
      t.boolean :case_number_found, null: true
      t.boolean :case_number_collection_date_found, null: true
    end
  end
end
