# This migration comes from abstractor (originally 20140816005228)
class AddNamespaceToAbstractorSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_subjects, :namespace_type, :string
    add_column :abstractor_subjects, :namespace_id, :integer
  end
end
