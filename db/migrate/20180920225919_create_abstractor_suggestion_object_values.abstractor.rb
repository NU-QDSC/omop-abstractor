# This migration comes from abstractor (originally 20131228041944)
class CreateAbstractorSuggestionObjectValues < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_suggestion_object_values do |t|
      t.integer :abstractor_suggestion_id
      t.integer :abstractor_object_value_id
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
