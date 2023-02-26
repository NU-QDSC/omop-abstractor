# This migration comes from abstractor (originally 20150616161849)
class AddWorkflowStatusFields < ActiveRecord::Migration[5.2]
  def change
    add_column :abstractor_subject_groups, :enable_workflow_status, :boolean, default: false
    add_column :abstractor_subject_groups, :workflow_status_submit, :string
    add_column :abstractor_subject_groups, :workflow_status_pend, :string
    add_column :abstractor_abstractions, :workflow_status, :string
  end
end
