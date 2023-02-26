class AddIndexToNoteStableIdentifierFull < ActiveRecord::Migration[5.2]
  def change
    add_index :note_stable_identifier_full, [:stable_identifer_hash_id], unique: false, name: 'index_note_stable_identifier_full_stable_identifer_hash_id'
  end
end
