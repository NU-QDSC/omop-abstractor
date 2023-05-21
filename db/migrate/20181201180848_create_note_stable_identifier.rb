class CreateNoteStableIdentifier < ActiveRecord::Migration[5.2]
  def change
    create_table :note_stable_identifier do |t|
      t.bigint :note_id, null: false
      t.string  :stable_identifier_path, null: false
      t.string  :stable_identifier_value, null: false
    end
  end
end