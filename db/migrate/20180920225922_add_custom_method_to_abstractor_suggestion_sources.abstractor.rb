# This migration comes from abstractor (originally 20140618140828)
class AddCustomMethodToAbstractorSuggestionSources < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_suggestion_sources, :custom_method, :string
  end
end
