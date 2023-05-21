# This migration comes from abstractor (originally 20150317204748)
class AddVocabularyColumnsToAbstractorObjectValues < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_object_values, :vocabulary_code, :string
    add_column :abstractor_object_values, :vocabulary, :string
    add_column :abstractor_object_values, :vocabulary_version, :string
  end
end
