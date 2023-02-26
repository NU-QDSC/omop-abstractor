# This migration comes from abstractor (originally 20131227205256)
class CreateAbstractorObjectValueVariants < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_object_value_variants do |t|
      t.integer :abstractor_object_value_id
      t.string :value
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
