class CreateOmopPiiMrn < ActiveRecord::Migration[5.2]
  def change
    create_table "pii_mrn", id: false, force: :cascade do |t|
      t.bigint "person_id", null: false
      t.string "health_system", limit: 50
      t.string "mrn", limit: 50
    end
  end
end
