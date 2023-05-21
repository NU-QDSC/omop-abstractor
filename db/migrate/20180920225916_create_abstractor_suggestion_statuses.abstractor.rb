# This migration comes from abstractor (originally 20131227211050)
class CreateAbstractorSuggestionStatuses < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_suggestion_statuses do |t|
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
