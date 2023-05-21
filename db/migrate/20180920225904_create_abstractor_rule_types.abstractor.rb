# This migration comes from abstractor (originally 20131227205354)
class CreateAbstractorRuleTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_rule_types do |t|
      t.string :name
      t.text :description
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
