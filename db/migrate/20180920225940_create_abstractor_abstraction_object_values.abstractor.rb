# This migration comes from abstractor (originally 20150918105120)
class CreateAbstractorAbstractionObjectValues < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_object_values do |t|
      t.integer :abstractor_abstraction_id
      t.integer :abstractor_object_value_id
      t.datetime :deleted_at

      t.timestamps
    end
  end
end



