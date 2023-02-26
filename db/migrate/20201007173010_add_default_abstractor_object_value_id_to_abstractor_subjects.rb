class AddDefaultAbstractorObjectValueIdToAbstractorSubjects < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_subjects, :default_abstractor_object_value_id, :integer
  end
end


