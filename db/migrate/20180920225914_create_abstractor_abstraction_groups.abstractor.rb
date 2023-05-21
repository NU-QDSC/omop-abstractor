# This migration comes from abstractor (originally 20131227210350)
class CreateAbstractorAbstractionGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_groups do |t|
      t.integer :abstractor_subject_group_id
      t.string :about_type
      t.integer :about_id
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
