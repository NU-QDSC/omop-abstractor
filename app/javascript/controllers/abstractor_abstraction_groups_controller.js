import { Controller } from "stimulus"
import WorkflowStatus from '../omop_abstractor/workflow_status'

export default class AbstractorAbstractionGroupsController extends Controller {
  static targets = []

  initialize() {
  }

  connect() {
  }

  validateCardinality(group_container) {
    var add_group_link, group_cardinality;
    group_cardinality = group_container.find('input[name="abstractor_subject_group_cardinality"]');
    add_group_link = group_container.find('.abstractor_group_add_link');
    if ((group_cardinality.length > 0) && (group_cardinality.val() === group_container.find('.abstractor_abstraction_group_member').length.toString())) {
      return $(add_group_link).hide();
    } else {
      return $(add_group_link).show();
    }
  }

  add() {
    var controller, currentTarget, abstractor_subject_groups_container, abstractor_abstraction_group, detail, status, xhr;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[0];
    status = detail[1];

    abstractor_subject_groups_container = $(event.currentTarget).closest(".abstractor_subject_groups_container");
      abstractor_subject_groups_container.find(".abstractor_subject_groups").append(xhr.responseText);
    controller.validateCardinality(abstractor_subject_groups_container);
    WorkflowStatus.toggleWorkflowStatus();
    return;
  }

  delete() {
    var controller, currentTarget, abstractor_subject_groups_container, abstractor_abstraction_group, detail, status, xhr;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[0];
    status = detail[1];

    abstractor_subject_groups_container = $(event.currentTarget).closest(".abstractor_subject_groups_container");
    abstractor_abstraction_group = $(event.currentTarget).closest(".abstractor_abstraction_group");
    abstractor_abstraction_group.html(xhr.responseText);
    controller.validateCardinality(abstractor_subject_groups_container);
    WorkflowStatus.toggleWorkflowStatus();
    return;
  }

  not_applicable_all() {
    var controller, currentTarget, abstractor_abstraction_group, detail, status, xhr;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[0];
    status = detail[1];

    abstractor_abstraction_group = $(event.currentTarget).closest(".abstractor_abstraction_group");
    abstractor_abstraction_group.html(xhr.responseText);
    return
  }

  unknown_all() {
    var controller, currentTarget, abstractor_abstraction_group, detail, status, xhr;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[0];
    status = detail[1];

    abstractor_abstraction_group = $(event.currentTarget).closest(".abstractor_abstraction_group");
    abstractor_abstraction_group.html(xhr.responseText);
    return
  }

  submit_abstractor_workflow_status(){
    var controller, currentTarget, abstractor_abstraction_group, detail, status, xhr;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[0];
    status = detail[1];

    abstractor_abstraction_group = $(event.currentTarget).closest(".abstractor_abstraction_group");
    abstractor_abstraction_group.html(xhr.responseText);
    return;
  }
}