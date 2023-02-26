# This migration comes from abstractor (originally 20131227205320)
class CreateAbstractorRelationTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_relation_types do |t|
      t.string :name
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
