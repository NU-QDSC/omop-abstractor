
class CreateCompareBreastCancerAbstractions < ActiveRecord::Migration[5.2]
  def change
    create_table :compare_breast_cancer_abstractions do |t|
      t.string  :abstractor_namespace_name
      t.string  :person_source_value
      t.integer  :note_id
      t.string  :stable_identifier_path
      t.string  :stable_identifier_value
      t.integer  :subject_id
      t.string  :procedure_occurrence_stable_identifier_path
      t.string  :procedure_occurrence_stable_identifier_value
      t.date  :procedure_date
      t.string  :has_cancer_histology
      t.text  :has_cancer_histology_suggestions
      t.string  :has_cancer_site
      t.text  :has_cancer_site_suggestions
      t.string  :has_cancer_site_laterality
      t.string  :has_cancer_pathologic_sbr_grade
      t.string  :has_cancer_recurrence_status
      t.string  :has_metastatic_cancer_histology
      t.text  :has_metastatic_cancer_histology_suggestions
      t.string  :has_metastatic_cancer_site
      t.text  :has_metastatic_cancer_site_suggestions
      t.string  :has_metastatic_cancer_primary_site
      t.string  :has_metastatic_cancer_site_laterality
      t.string  :has_metastatic_cancer_recurrence_status
      t.string  :procedure_occurrence_stable_identifier_surgery_path
      t.string  :procedure_occurrence_stable_identifier_surgery_value
      t.date  :surgery_procedure_date
      t.string  :surgery_concept_name
      t.string  :surgery_vocabulary_id
      t.string  :surgery_concept_code
      t.string  :surgery_procedure_source_value
      t.string  :has_surgery_date
      t.date     :has_surgery_date_normalized
      t.string  :pathological_tumor_staging_category
      t.string  :pathological_nodes_staging_category
      t.string  :pathological_metastasis_staging_category
      t.string  :has_tumor_size
      t.string  :has_estrogen_receptor_status
      t.string  :has_progesterone_receptor_status
      t.string  :has_her2_status
    end
  end
end
