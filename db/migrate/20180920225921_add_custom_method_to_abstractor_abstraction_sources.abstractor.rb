# This migration comes from abstractor (originally 20140618140759)
class AddCustomMethodToAbstractorAbstractionSources < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_abstraction_sources, :custom_method, :string
  end
end
