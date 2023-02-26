# This migration comes from abstractor (originally 20131227205732)
class CreateAbstractorSubjectRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_subject_relations do |t|
      t.integer :subject_id
      t.integer :object_id
      t.integer :abstractor_relation_type_id
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
