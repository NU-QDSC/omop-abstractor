class AddFavorMoreSpecificToAbstractorObjectValues < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_object_values, :favor_more_specific, :boolean
  end
end
