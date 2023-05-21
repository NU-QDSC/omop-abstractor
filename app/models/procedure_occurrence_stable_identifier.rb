class ProcedureOccurrenceStableIdentifier < ApplicationRecord
  self.table_name = 'procedure_occurrence_stable_identifier'

  def procedure_occurrence
    ProcedureOccurrence.where(procedure_occurrence_id: self.procedure_occurrence_id).first
  end
end