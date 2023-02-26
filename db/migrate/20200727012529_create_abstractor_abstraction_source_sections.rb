class CreateAbstractorAbstractionSourceSections < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_abstraction_source_sections do |t|
      t.integer :abstractor_abstraction_source_id,    null: false
      t.integer :abstractor_section_id,               null: false
      t.datetime :deleted_at
      t.timestamps
    end
  end
end