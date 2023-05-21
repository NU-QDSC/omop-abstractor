class CreatePrimaryCnsPathologyCases < ActiveRecord::Migration[5.2]
  def change
    create_table :primary_cns_pathology_cases do |t|
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
      t.string  :integrated_mention, null: true
      t.string  :has_cancer_integrated_histology, null: true
      t.text    :has_cancer_integrated_histology_suggestions, null: true
      t.string  :has_cancer_site, null: true
      t.text    :has_cancer_site_suggestions, null: true
      t.string  :has_cancer_site_laterality, null: true
      t.string  :has_cancer_who_grade, null: true
      t.string  :has_metastatic_cancer_primary_site, null: true
      t.string  :has_cancer_recurrence_status, null: true
      t.string  :has_idh1_status, null: true
      t.string  :has_idh2_status, null: true
      t.string  :has_1p_status, null: true
      t.string  :has_19q_status, null: true
      t.string  :has_10q_pten_status, null: true
      t.string  :has_mgmt_status, null: true
      t.string  :has_ki67, null: true
      t.string  :has_p53, null: true
      t.string  :has_surgery_date, null: true
    end
  end
end
