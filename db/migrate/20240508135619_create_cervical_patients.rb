class CreateCervicalPatients < ActiveRecord::Migration[5.2]
  def change
    create_table :cervical_patients do |t|
      t.bigint  :patient_ir_id, null: true
      t.string  :west_mrn, null: true
      t.string  :race_nih, null: true
      t.string  :ethnic_group_nih, null: true
      t.string  :gender, null: true
      t.date  :birth_date, null: true
    end
  end
end
