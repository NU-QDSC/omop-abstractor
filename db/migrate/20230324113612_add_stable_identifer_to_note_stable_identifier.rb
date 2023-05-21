class AddStableIdentiferToNoteStableIdentifier < ActiveRecord::Migration[5.2]
  def change
    add_column :note_stable_identifier, :stable_identifier_value_1, :string
  end
end
