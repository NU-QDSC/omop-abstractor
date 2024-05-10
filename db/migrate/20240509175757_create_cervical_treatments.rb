class CreateCervicalTreatments < ActiveRecord::Migration[5.2]
  def change
    create_table :cervical_treatments do |t|
      t.bigint  :patient_ir_id, null: true
      t.string  :cpt_name, null: true
      t.string  :treatment_type, null: true
      t.date    :treatment_date, null: true
      t.bigint  :treatment_year, null: true
      t.string  :treatment_provenance, null: true
      t.bigint  :interval_days_from_first_pathology, null: true
      t.bigint  :age_at_treatment, null: true
    end
  end
end
