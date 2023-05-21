# This migration comes from abstractor (originally 20131227205219)
class CreateAbstractorObjectValues < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_object_values do |t|
      t.string :value
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
