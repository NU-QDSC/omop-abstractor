# This migration comes from abstractor (originally 20131227205610)
class CreateAbstractorAbstractionSchemaRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_schema_relations do |t|
      t.integer :subject_id
      t.integer :object_id
      t.integer :abstractor_relation_type_id
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
