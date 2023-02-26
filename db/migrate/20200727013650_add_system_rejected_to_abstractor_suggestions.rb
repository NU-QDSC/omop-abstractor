class AddSystemRejectedToAbstractorSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_suggestions, :system_rejected, :boolean, default: false
  end
end
