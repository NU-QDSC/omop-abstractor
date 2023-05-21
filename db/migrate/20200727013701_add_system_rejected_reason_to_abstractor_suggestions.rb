class AddSystemRejectedReasonToAbstractorSuggestions < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_suggestions, :system_rejected_reason, :string
  end
end
