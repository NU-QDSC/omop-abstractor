# This migration comes from abstractor (originally 20131227210244)
class CreateAbstractorSubjectGroupMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_subject_group_members do |t|
      t.integer :abstractor_subject_id
      t.integer :abstractor_subject_group_id
      t.integer :display_order
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
