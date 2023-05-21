class CreateIcdo3Histologies < ActiveRecord::Migration[5.2]
  def change
    create_table :icdo3_histologies do |t|
      t.string  :version,               null: false
      t.string  :minor_version,         null: false
      t.string  :icdo3_code,            null: false
      t.string  :icdo3_name,            null: false
      t.string  :icdo3_description,     null: false
      t.string  :level,                 null: true
      t.string  :code_reference,        null: true
      t.string  :obs,                   null: true
      t.string  :see_also,              null: true
      t.string  :includes,              null: true
      t.string  :excludes,              null: true
      t.string  :other_text,            null: true
      t.string  :category,              null: true
      t.string  :subcategory,           null: true
      t.integer :grade,                 null: true
      t.timestamps
    end
  end
end