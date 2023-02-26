class AddValueNewNormalizedRawToNlpComparisons < ActiveRecord::Migration[5.2]
  def change
    add_column :nlp_comparisons, :value_new_normalized_raw, :text
  end
end
