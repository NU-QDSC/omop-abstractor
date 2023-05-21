class CreateProcedureOccurrenceStableIdentifier < ActiveRecord::Migration[5.2]
  def change
    create_table :procedure_occurrence_stable_identifier do |t|
      t.bigint :procedure_occurrence_id, null: false
      t.string  :stable_identifier_path, null: false
      t.string  :stable_identifier_value_1, null: false
      t.string  :stable_identifier_value_2, null: true
      t.string  :stable_identifier_value_3, null: true
      t.string  :stable_identifier_value_4, null: true
      t.string  :stable_identifier_value_5, null: true
      t.string  :stable_identifier_value_6, null: true
    end
  end
end