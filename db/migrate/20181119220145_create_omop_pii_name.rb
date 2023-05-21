class CreateOmopPiiName < ActiveRecord::Migration[5.2]
  def change
    create_table "pii_name", id: false, force: :cascade do |t|
      t.bigint "person_id", null: false
      t.string "first_name", limit: 200
      t.string "middle_name", limit: 508
      t.string "last_name", limit: 200
      t.string "suffix", limit: 50
      t.string "prefix", limit: 50
    end
  end
end
