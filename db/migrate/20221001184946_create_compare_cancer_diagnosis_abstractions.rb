class CreateCompareCancerDiagnosisAbstractions < ActiveRecord::Migration[5.2]
  def change
    create_table :compare_cancer_diagnosis_abstractions do |t|
      t.integer  :source_id
      t.integer  :note_id
      t.string   :stable_identifier_path
      t.string   :stable_identifier_value
      t.integer  :subject_id
      t.string   :has_cancer_histology
      t.string   :has_cancer_histology_suggestions
      t.string   :has_cancer_histology_other
      t.string   :has_cancer_histology_other_suggestions
      t.string   :has_metastatic_cancer_histology
      t.string   :has_metastatic_cancer_histology_suggestions
      t.string   :has_metastatic_cancer_histology_other
      t.string   :has_metastatic_cancer_histology_other_suggestions
      t.string   :has_cancer_site
      t.string   :has_cancer_site_suggestions
      t.string   :has_cancer_site_other
      t.string   :has_cancer_site_other_suggestions
      t.string   :has_cancer_site_laterality
      t.string   :has_cancer_who_grade
      t.string   :has_metastatic_cancer_primary_site
      t.string   :has_cancer_recurrence_status
      t.string   :abstractor_namespace_name
      t.string   :abstractor_subject_group_name
      t.string   :system_type
      t.string   :status
    end
  end
end
