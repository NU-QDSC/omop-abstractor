class AddAbstractorSectionMentionTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :abstractor_section_mention_types do |t|
      t.string    :name, null: false
      t.timestamps
    end
  end
end
