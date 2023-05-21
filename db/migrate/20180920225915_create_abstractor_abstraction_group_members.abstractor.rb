# This migration comes from abstractor (originally 20131227210353)
class CreateAbstractorAbstractionGroupMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_group_members do |t|
      t.integer :abstractor_abstraction_group_id
      t.integer :abstractor_abstraction_id
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
