class AddAnchorToAbstractorSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_subjects, :anchor, :boolean
  end
end
