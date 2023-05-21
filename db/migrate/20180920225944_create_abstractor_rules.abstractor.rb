# This migration comes from abstractor (originally 20170313114740)
class CreateAbstractorRules < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_rules do |t|
      t.text :rule,             null: false
      t.datetime :deleted_at,   null: true

      t.timestamps
    end
  end
end


