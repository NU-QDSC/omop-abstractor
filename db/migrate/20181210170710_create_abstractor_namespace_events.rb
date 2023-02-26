class CreateAbstractorNamespaceEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_namespace_events do |t|
      t.integer :abstractor_namespace_id,   null: false
      t.string  :eventable_type,            null: false
      t.integer :eventable_id,              null: false
      t.timestamps
    end
  end
end