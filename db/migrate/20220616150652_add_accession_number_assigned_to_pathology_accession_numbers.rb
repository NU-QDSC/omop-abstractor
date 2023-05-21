class AddAccessionNumberAssignedToPathologyAccessionNumbers < ActiveRecord::Migration[5.2]
  def change
    add_column :pathology_accession_numbers, :accession_number_assigned, :string
  end
end
