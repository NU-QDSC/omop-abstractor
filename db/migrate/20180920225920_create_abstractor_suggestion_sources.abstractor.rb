# This migration comes from abstractor (originally 20131228041945)
class CreateAbstractorSuggestionSources < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_suggestion_sources do |t|
      t.integer :abstractor_abstraction_source_id
      t.integer :abstractor_suggestion_id
      t.text :match_value
      t.text :sentence_match_value
      t.integer :source_id
      t.string :source_method
      t.string :source_type
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
