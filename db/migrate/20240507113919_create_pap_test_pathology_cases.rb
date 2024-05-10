class CreatePapTestPathologyCases < ActiveRecord::Migration[5.2]
  def change
    create_table :pap_test_pathology_cases do |t|
      t.bigint  :patient_ir_id, null: true
      t.string  :accession_nbr_formatted, null: true
      t.date    :accessioned_datetime, null: true
      t.date    :case_collect_datetime, null: true
      t.string  :group_desc, null: true
      t.string  :has_cancer_histology_discrete, null: true
      t.string  :has_cancer_histology, null: true
    end
  end
end
