# This migration comes from abstractor (originally 20170309114656)
class AddCaseSensitiveToAbstractorObjectValueVariants < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_object_value_variants, :case_sensitive, :boolean, default: false
  end
end