class AddAbstractorSectionMentionTypeIdToAbstractorSections < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_sections, :abstractor_section_mention_type_id, :integer
  end
end
