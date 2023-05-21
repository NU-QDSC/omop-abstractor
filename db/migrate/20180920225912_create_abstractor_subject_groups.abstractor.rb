# This migration comes from abstractor (originally 20131227210211)
class CreateAbstractorSubjectGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_subject_groups do |t|
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
