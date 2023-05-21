class AddSystemAcceptedReasonToAbstractorSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_suggestions, :system_accepted_reason, :string
  end
end
