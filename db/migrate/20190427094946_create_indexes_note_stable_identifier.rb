class CreateIndexesNoteStableIdentifier < ActiveRecord::Migration[5.2]
  def change
    add_index(:note_stable_identifier, [:note_id], name: 'idx_note_stable_identifier_1')
    add_index(:note_stable_identifier, [:stable_identifier_path, :stable_identifier_value], name: 'idx_note_stable_identifier_2')
  end
end
