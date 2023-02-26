# This migration comes from abstractor (originally 20170309114645)
class AddCaseSensitiveToAbstractorObjectValues < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_object_values, :case_sensitive, :boolean, default: false
  end
end
