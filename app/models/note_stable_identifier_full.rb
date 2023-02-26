class NoteStableIdentifierFull < ApplicationRecord
  self.table_name = 'note_stable_identifier_full'

  def note_stable_identifier
    NoteStableIdentifier.where(stable_identifier_path: self.stable_identifier_path, stable_identifier_value: self.stable_identifier_value).first
  end
end