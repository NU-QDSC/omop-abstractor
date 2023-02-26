# This migration comes from abstractor (originally 20150505022228)
class AddSubtypeToAbstractorAbstractionGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_abstraction_groups, :subtype, :string
  end
end
