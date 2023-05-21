class CreateOmopPiiPhoneNumber < ActiveRecord::Migration[5.2]
  def change
    create_table "pii_phone_number", id: false, force: :cascade do |t|
      t.bigint "person_id", null: false
      t.string "phone_number", limit: 50
    end
  end
end
