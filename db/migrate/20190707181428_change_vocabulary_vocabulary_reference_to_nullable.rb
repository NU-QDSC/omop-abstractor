class ChangeVocabularyVocabularyReferenceToNullable < ActiveRecord::Migration[5.2]
  def change
    change_column_null :vocabulary, :vocabulary_reference, true
  end
end
