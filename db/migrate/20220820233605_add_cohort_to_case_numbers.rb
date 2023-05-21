class AddCohortToCaseNumbers < ActiveRecord::Migration[5.2]
  def change
    add_column :case_numbers, :cohort, :string
  end
end
