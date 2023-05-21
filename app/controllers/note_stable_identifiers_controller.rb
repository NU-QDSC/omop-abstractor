class NoteStableIdentifiersController < ApplicationController
  # before_action :authenticate_user!
  skip_before_action :verify_authenticity_token
  before_action :load_note_stable_identifier

  def abstractor_suggestions
    begin
        @note_stable_identifier.process_abstractor_suggestions(params)
    rescue Exception => e
      puts 'Kaboom!'
      puts 'begin note_stable_identifier.id'
      puts @note_stable_identifier.id
      puts 'end note_stable_identifier.id'
      puts e.class
      puts e.message
      puts e.backtrace.join("\n")
      File.write('lib/setup/data_out/bad_guys.txt', "Kaboom NOTE_ID:#{@note_stable_identifier.note.note_id}", mode: 'a+')
      File.write('lib/setup/data_out/bad_guys.txt', "\n", mode: 'a+')
    end
  end

  private
    def load_note_stable_identifier
      @note_stable_identifier = SqlAudit.find_and_audit('mjg994', NoteStableIdentifier.where(id: params[:id])).first
    end
end