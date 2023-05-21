class AddIndexToNoteNoteDate < ActiveRecord::Migration[5.2]
  def change
    add_index :note, [:note_date], unique: false
  end
end
