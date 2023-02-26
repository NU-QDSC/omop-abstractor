# This migration comes from abstractor (originally 20131227205529)
class CreateAbstractorAbstractionSchemaPredicateVariants < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_schema_predicate_variants do |t|
      t.integer :abstractor_abstraction_schema_id
      t.string :value
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
