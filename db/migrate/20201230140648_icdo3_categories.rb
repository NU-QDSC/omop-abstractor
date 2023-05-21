class Icdo3Categories < ActiveRecord::Migration[5.2]
  def change
    create_table :icdo3_categories do |t|
      t.string  :version,                   null: false
      t.string  :category,                  null: false
      t.string  :categorizable_type,        null: false
      t.integer :parent_icdo3_category_id,  null: true
      t.timestamps
    end
  end
end