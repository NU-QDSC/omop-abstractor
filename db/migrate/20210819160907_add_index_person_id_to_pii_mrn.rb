class AddIndexPersonIdToPiiMrn < ActiveRecord::Migration[5.2]
  def change
      add_index :pii_mrn, [:person_id], unique: false , name: 'index_person_id'
  end
end
