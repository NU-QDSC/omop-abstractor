class CreateIcdo3HistologySynonyms < ActiveRecord::Migration[5.2]
  def change
    create_table :icdo3_histology_synonyms do |t|
      t.integer :icdo3_histology_id,        null: false
      t.string :icdo3_synonym_description,  null: false
      t.timestamps
    end
  end
end
