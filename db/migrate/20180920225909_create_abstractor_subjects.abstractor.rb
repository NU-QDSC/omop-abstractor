# This migration comes from abstractor (originally 20131227205652)
class CreateAbstractorSubjects < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_subjects do |t|
      t.integer :abstractor_abstraction_schema_id
      t.integer :abstractor_rule_type_id
      t.string :subject_type
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
