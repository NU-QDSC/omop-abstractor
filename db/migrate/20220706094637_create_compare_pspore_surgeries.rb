class CreateComparePsporeSurgeries < ActiveRecord::Migration[5.2]
  def change
    create_table :compare_pspore_surgeries do |t|
      t.string  :record_id, null: true
      t.string  :pop_id, null: true
      t.string  :case_number, null: true
      t.string  :nmhc_mrn, null: true
      t.string  :diagnosis, null: true
      t.string  :diagnosis_abstractor, null: true
      t.string  :affiliate, null: true
      t.date    :registration_date, null: true
      t.date    :consent_date, null: true
      t.string  :surgery_date, null: true
      t.string  :surgery_date_abstractor, null: true
      t.string  :surgery_type, null: true
      t.string  :surgery_type_abstractor, null: true
      t.string  :pathological_staging_t, null: true
      t.string  :pathological_staging_t_abstractor, null: true
      t.string  :pathological_staging_n, null: true
      t.string  :pathological_staging_n_abstractor, null: true
      t.string  :pathological_staging_m, null: true
      t.string  :pathological_staging_m_abstractor, null: true
      t.string  :surgery_prostate_weight, null: true
      t.string  :surgery_prostate_weight_abstractor, null: true
      t.string  :nervesparing_procedure, null: true
      t.string  :extra_capsular_extension, null: true
      t.string  :extra_capsular_extension_abstractor, null: true
      t.string  :margins, null: true
      t.string  :margins_abstractor, null: true
      t.string  :seminal_vesicle, null: true
      t.string  :seminal_vesicle_abstractor, null: true
      t.string  :lymph_nodes, null: true
      t.string  :lymph_nodes_abstractor, null: true
      t.string  :lymphatic_vascular_invasion, null: true
      t.string  :lymphatic_vascular_invasion_abstractor, null: true
      t.string  :surgery_perineural, null: true
      t.string  :surgery_perineural_abstractor, null: true
      t.string  :surgery_gleason_1, null: true
      t.string  :surgery_gleason_1_abstractor, null: true
      t.string  :surgery_gleason_2, null: true
      t.string  :surgery_gleason_2_abstractor, null: true
      t.string  :surgery_gleason_tertiary, null: true
      t.string  :surgery_precentage_of_prostate_cancer_tissue, null: true
      t.string  :surgery_precentage_of_prostate_cancer_tissue_abstractor, null: true
      t.string  :accession_number
    end
  end
end

# record_id
# pop_id
# case_number
# nmhc_mrn
# diagnosis
# treating_physician
# race
# birth_date
# death_date
# cause_of_death
# affiliate
# clinical_staging_t
# record_id
# pop_id
# surgery_date
# surgery_type
# pathological_staging_t
# pathological_staging_n
# pathological_staging_m
# surgery_prostate_weight
# nervesparing_procedure
# extra_capsular_extension
# margins
# seminal_vesicle
# lymph_nodes
# lymphatic_vascular_invasion
# surgery_perineural
# surgery_gleason_1
# surgery_gleason_2
# surgery_gleason_tertiary
# surgery_precentage_of_prostate_cancer_tissue
