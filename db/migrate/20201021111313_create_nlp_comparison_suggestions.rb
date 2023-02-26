class CreateNlpComparisonSuggestions < ActiveRecord::Migration[5.2]
  def change
    create_table :nlp_comparison_suggestions do |t|
      t.integer :nlp_comparison_id,  null: false
      t.string  :source,             null: false
      t.string  :suggested_value,    null: false
    end
  end
end
