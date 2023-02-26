class CreateCaseNumbers < ActiveRecord::Migration[5.2]
  def change
    create_table :case_numbers do |t|
      t.string  :case_number, null: true
      t.string  :west_mrn, null: true
    end
  end
end
