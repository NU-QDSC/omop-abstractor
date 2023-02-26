# This migration comes from abstractor (originally 20131227205831)
class CreateAbstractorAbstractionSources < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_sources do |t|
      t.integer :abstractor_subject_id
      t.string :from_method
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
