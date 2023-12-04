class CreateAmlSufficiencyPathologyCases < ActiveRecord::Migration[5.2]
  def change
    create_table :aml_sufficiency_pathology_cases do |t|
      t.string  :abstractor_namespace_name, null: true
      t.string  :west_mrn, null: true
      t.string  :note_stable_identifier_path, null: true
      t.string  :note_stable_identifier_value_1, null: true
      t.string  :note_stable_identifier_value_2, null: true
      t.bigint  :note_id, null: true
      t.string  :pathology_stable_identifier_path, null: true
      t.string  :pathology_stable_identifier_value_1, null: true
      t.date    :pathology_procedure_date, null: true
      t.string  :pathology_provider_name, null: true
      t.string  :pathology_procedure_source_value, null: true
      t.string  :pathology_concept_name, null: true
      t.string  :surgery_stable_identifier_path, null: true
      t.string  :surgery_stable_identifier_value_1, null: true
      t.date    :surgery_procedure_date, null: true
      t.string  :surgery_provider_name, null: true
      t.string  :surgery_procedure_source_value, null: true
      t.string  :surgery_concept_name, null: true
      t.string  :has_bone_marrow_aspirate_adequacy, null: true
      t.text    :has_bone_marrow_aspirate_adequacy_suggestions, null: true
      t.text    :has_bone_marrow_aspirate_adequacy_suggestion_sentences, null: true
    end
  end
end
