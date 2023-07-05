class CreateProstateSurgeryPathologyCases < ActiveRecord::Migration[5.2]
  def change
    create_table :prostate_surgery_pathology_cases do |t|
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
      t.string  :diagnosis_type, null: true
      t.string  :has_cancer_histology, null: true
      t.text    :has_cancer_histology_suggestions, null: true
      t.string  :has_cancer_site, null: true
      t.text    :has_cancer_site_suggestions, null: true
      t.string  :has_gleason_score_grade, null: true
      t.string  :has_perineural_invasion, null: true
      t.string  :has_prostate_weight, null: true
      t.string  :pathological_tumor_staging_category, null: true
      t.string  :pathological_nodes_staging_category, null: true
      t.string  :pathological_metastasis_staging_category, null: true
      t.string  :has_extraprostatic_extension, null: true
      t.string  :has_seminal_vesicle_invasion, null: true
      t.string  :has_margin_status,  null: true
      t.string  :has_number_lymph_nodes_examined, null: true
      t.string  :has_number_lymph_nodes_positive_tumor, null: true
      t.string  :has_surgery_date, null: true
    end
  end
end