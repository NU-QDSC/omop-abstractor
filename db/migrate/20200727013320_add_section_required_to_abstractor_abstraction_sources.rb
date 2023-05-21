class AddSectionRequiredToAbstractorAbstractionSources < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_abstraction_sources, :section_required, :boolean, default: false
  end
end
