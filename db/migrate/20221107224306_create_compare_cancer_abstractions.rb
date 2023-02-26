class CreateCompareCancerAbstractions < ActiveRecord::Migration[5.2]
  def change
    create_table :compare_cancer_abstractions do |t|
      t.integer  :source_id
      t.integer  :note_id
      t.string   :stable_identifier_path
      t.string   :stable_identifier_value
      t.integer  :subject_id
      t.string   :has_idh1_status
      t.string   :has_idh2_status
      t.string   :has_mgmt_status
      t.string   :has_1p_status
      t.string   :has_19q_status
      t.string   :has_10q_PTEN_status
      t.string   :has_ki67
      t.string   :has_p53
      t.string   :has_surgery_date
      t.string   :abstractor_namespace_name
      t.string   :abstractor_subject_group_name
      t.string   :system_type
      t.string   :status
    end
  end
end