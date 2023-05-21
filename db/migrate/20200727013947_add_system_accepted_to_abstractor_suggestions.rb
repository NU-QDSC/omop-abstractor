class AddSystemAcceptedToAbstractorSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_suggestions, :system_accepted, :boolean, default: false
  end
end
