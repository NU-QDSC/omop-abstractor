class AddEdwUpgradeFieldsToNoteStableIdentifierAndNoteStableIdentifierFull < ActiveRecord::Migration[5.2]
  def change
    add_column :note_stable_identifier, :stable_identifier_path_2, :string
    add_column :note_stable_identifier, :stable_identifier_value_2, :string
    add_column :note_stable_identifier, :stable_identifer_hash_id, :string

    add_column :note_stable_identifier_full, :stable_identifier_path_2, :string
    add_column :note_stable_identifier_full, :stable_identifier_value_2, :string
    add_column :note_stable_identifier_full, :stable_identifer_hash_id, :string
  end
end