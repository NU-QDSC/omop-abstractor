class AddSiteToCaseNumbers < ActiveRecord::Migration[5.2]
  def change
    add_column :case_numbers, :site, :string
  end
end
