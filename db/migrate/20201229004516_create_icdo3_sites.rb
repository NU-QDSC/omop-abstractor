class CreateIcdo3Sites < ActiveRecord::Migration[5.2]
  def change
    create_table :icdo3_sites do |t|
      t.string  :version,               null: false
      t.string  :minor_version,         null: false
      t.string  :icdo3_code,            null: false
      t.string  :icdo3_name,            null: false
      t.string  :icdo3_description,     null: false
      t.string  :category,              null: true
      t.string  :subcategory,           null: true
      t.timestamps
    end
  end
end