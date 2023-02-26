# This migration comes from abstractor (originally 20150223033848)
class AddCustomNlpProviderToAbstractorAbstractionSources < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_abstraction_sources, :custom_nlp_provider, :string
  end
end
