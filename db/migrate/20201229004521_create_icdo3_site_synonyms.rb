class CreateIcdo3SiteSynonyms < ActiveRecord::Migration[5.2]
  def change
    create_table :icdo3_site_synonyms do |t|
      t.integer :icdo3_site_id,        null: false
      t.string :icdo3_synonym_description,  null: false
      t.timestamps
    end
  end
end
