class AddIndexesForPerformance < ActiveRecord::Migration[5.2]
  def change
    add_index :abstractor_abstraction_object_values, [:abstractor_abstraction_id], unique: false, name: 'index_abstractor_abstraction_object_values_1'
    add_index :abstractor_abstraction_object_values, [:abstractor_object_value_id], unique: false, name: 'index_abstractor_abstraction_object_values_2'
    add_index :procedure_occurrence, [:provider_id], unique: false
    add_index :provider, [:provider_name], unique: false
  end
end
