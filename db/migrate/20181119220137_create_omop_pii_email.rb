class CreateOmopPiiEmail < ActiveRecord::Migration[5.2]
  def change
    create_table "pii_email", id: false, force: :cascade do |t|
      t.bigint "person_id", null: false
      t.string "email", limit: 255
    end
  end
end
