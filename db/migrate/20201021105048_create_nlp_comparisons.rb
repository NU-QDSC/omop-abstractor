class CreateNlpComparisons < ActiveRecord::Migration[5.2]
  def change
    create_table :nlp_comparisons do |t|
      t.string  :stable_identifier_path,               null: false
      t.string  :stable_identifier_value,              null: false
      t.integer :note_id,                              null: false
      t.integer :note_stable_identifier_id_old,        null: true
      t.integer :note_stable_identifier_id_new,        null: true
      t.string  :abstractor_subject_group_name,        null: true
      t.integer :abstractor_abstraction_group_id_old,  null: true
      t.integer :abstractor_abstraction_group_id_new,  null: true
      t.integer :abstractor_subject_group_counter,     null: true
      t.integer :abstractor_abstraction_id_old,        null: false
      t.string  :predicate_old,                        null: false
      t.string  :predicate_new,                        null: true
      t.string  :predicate,                            null: false
      t.string  :value_old,                            null: true
      t.float   :value_old_float,                      null: true
      t.string  :value_old_normalized,                 null: true
      t.string  :value_new,                            null: true
      t.float   :value_new_float,                      null: true
      t.string  :value_new_normalized,                 null: true
      t.timestamps
    end
  end
end