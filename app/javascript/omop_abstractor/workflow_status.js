class WorkflowStatus {
  constructor() {
  }

  static allAnswered() {
    var abstractor_abstractions, set_abstractions;
    abstractor_abstractions = $('.abstractor_abstraction');
    set_abstractions = $('.abstractor_abstractions').find('.abstractor_abstraction input:checkbox:checked').map(function() {
      return $(this).val();
    }).get();
    if (abstractor_abstractions.length === set_abstractions.length) {
      return true;
    } else {
      return false;
    }
  }

  static toggleWorkflowStatus() {
    var controller = this;
    if (this.allAnswered()) {
      $('.abstractor_update_workflow_status_link').removeClass('abstractor_update_workflow_status_link_disabled');
      $('.abstractor_update_workflow_status_link').addClass('abstractor_update_workflow_status_link_enabled');
      return $('.abstractor_update_workflow_status_link').prop('disabled', false);
    } else {
      $('.abstractor_update_workflow_status_link').removeClass('abstractor_update_workflow_status_link_enabled');
      $('.abstractor_update_workflow_status_link').addClass('abstractor_update_workflow_status_link_disabled');
      return $('.abstractor_update_workflow_status_link').prop('disabled', true);
    }
  }

  static toggleGroupWorkflowStatus(abstractor_abstraction_group) {
    var abstractor_abstractions, set_abstractions;

    abstractor_abstractions = $(abstractor_abstraction_group).find('.abstractor_abstraction');

    set_abstractions = $(abstractor_abstraction_group).find('.abstractor_abstraction input:checkbox:checked').map(function() {
      return $(this).val();
    }).get();

    if (abstractor_abstractions.length === set_abstractions.length) {
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').removeClass('abstractor_group_update_workflow_status_link_disabled');
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').addClass('abstractor_group_update_workflow_status_link_enabled');
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').prop('disabled', false);
    } else {
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').removeClass('abstractor_group_update_workflow_status_link_enabled');
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').addClass('abstractor_group_update_workflow_status_link_disabled');
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').prop('disabled', true);
    }
  }

}
export default WorkflowStatus