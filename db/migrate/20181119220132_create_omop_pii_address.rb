class CreateOmopPiiAddress < ActiveRecord::Migration[5.2]
  def change
    create_table "pii_address", id: false, force: :cascade do |t|
      t.bigint "person_id", null: false
      t.bigint "location_id"
    end
  end
end