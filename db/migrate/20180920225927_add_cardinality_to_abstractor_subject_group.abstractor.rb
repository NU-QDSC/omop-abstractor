# This migration comes from abstractor (originally 20141028020332)
class AddCardinalityToAbstractorSubjectGroup < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_subject_groups, :cardinality, :integer
  end
end
