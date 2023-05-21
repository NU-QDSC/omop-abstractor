class Icdo3Categorizations < ActiveRecord::Migration[5.2]
  def change
    create_table :icdo3_categorizations do |t|
      t.integer :icdo3_category_id,  null: false
      t.integer :categorizable_id,    null: false
      t.string  :categorizable_type,  null: false
      t.timestamps
    end
  end
end
