import { Controller } from "stimulus"
import WorkflowStatus from '../omop_abstractor/workflow_status'
import Hightlight from '../omop_abstractor/highlight'

export default class AbstractorAbstractionController extends Controller {
  static targets = ["suggestion"]

  initialize() {
  }

  connect() {
  }

  render() {
    var controller, currentTarget, abstractor_abstraction_group, abstractorAbstraction, detail, status, xhr;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[0];
    status = detail[1];
    abstractor_abstraction_group = $(currentTarget).closest('.abstractor_abstraction_group');
    abstractorAbstraction = $(currentTarget).closest(".abstractor_abstraction")
    abstractorAbstraction.html(xhr.responseText);
    WorkflowStatus.toggleGroupWorkflowStatus(abstractor_abstraction_group);
    WorkflowStatus.toggleWorkflowStatus();
    controller.clearHighlights();

    return;
  }

  clear() {
    event.preventDefault();
    var controller, currentTarget;
    controller = this;
    currentTarget = event.currentTarget;
    Rails.ajax({
      url: $(currentTarget).attr('href'),
      type: "PUT",
      data: {
        format: 'html',
        '_method': 'put',
        'abstractor_abstraction': {}
      },
      success: function(data) {
        var abstractor_abstraction_group;
        abstractor_abstraction_group = $(currentTarget).closest('.abstractor_abstraction_group');
        $(currentTarget).closest(".abstractor_abstraction").html(new XMLSerializer().serializeToString(data));
        WorkflowStatus.toggleGroupWorkflowStatus(abstractor_abstraction_group);
        WorkflowStatus.toggleWorkflowStatus();
      }
    });
    return;
  }

  setupEditForm() {
    $('select').formSelect();
    $(".abstractor_datepicker").datepicker({    
      format: "mm/dd/yyyy",
      changeMonth: true,
      changeYear: true,
      yearRange: [1900,2023]
    });
    return;
  }

  edit() {
    event.preventDefault();
    var controller, currentTarget, abstractor_abstraction_group, parent_div, parent_div_new;
    controller = this;
    currentTarget = event.currentTarget;
    $('.abstractor_update_workflow_status_link').removeClass('abstractor_update_workflow_status_link_enabled');
    $('.abstractor_update_workflow_status_link').addClass('abstractor_update_workflow_status_link_disabled');
    $('.abstractor_update_workflow_status_link').prop('disabled', true);
    abstractor_abstraction_group = $(currentTarget).closest('.abstractor_abstraction_group');
    parent_div = $(currentTarget).closest(".abstractor_abstraction");
    parent_div.load($(currentTarget).attr("href"), function() {
      controller.setupEditForm();
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').removeClass('abstractor_group_update_workflow_status_link_enabled');
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').addClass('abstractor_group_update_workflow_status_link_disabled');
      $(abstractor_abstraction_group).find('.abstractor_group_update_workflow_status_link').prop('disabled', true);
    });
    parent_div.addClass("highlighted");

    return;
  }

  saveError() {
    var controller, currentTarget, abstractor_abstraction_group, detail, status, xhr, abstractorAbstraction, selectWrappers;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    status = detail[1];
    xhr = detail[2];
    abstractorAbstraction = $(currentTarget).closest(".abstractor_abstraction")
    abstractorAbstraction.html(xhr.responseText);
    controller.setupEditForm();
    selectWrappers = abstractorAbstraction.find('.select-wrapper')
    selectWrappers.addClass('invalid');
    WorkflowStatus.toggleGroupWorkflowStatus(abstractor_abstraction_group);
    WorkflowStatus.toggleWorkflowStatus();

    return;
  }

  save() {
    var controller, currentTarget, detail, xhr, abstractor_abstraction_group, abstractor_abstraction, parent_div;
    controller = this;
    currentTarget = event.currentTarget;
    detail = event.detail;
    xhr = detail[2];
    abstractor_abstraction_group = $(currentTarget).closest('.abstractor_abstraction_group');
    abstractor_abstraction = $(currentTarget).closest(".abstractor_abstraction");
    abstractor_abstraction.html(xhr.responseText);
    abstractor_abstraction.removeClass("highlighted");
    WorkflowStatus.toggleGroupWorkflowStatus(abstractor_abstraction_group);
    WorkflowStatus.toggleWorkflowStatus();
    controller.clearHighlights();

    return;
  }

  validateWorkflowStatus() {
    var controller, abstractionWorkflowStatus;
    controller = this;

    abstractionWorkflowStatus = $(".abstraction_workflow_status_form input[name='abstraction_workflow_status']").val();
    if (!WorkflowStatus.allAnswered() && abstractionWorkflowStatus !== 'pending') {
      WorkflowStatus.toggleWorkflowStatus();
      alert('Validation Error: please set a value for all data points before submission.');
      event.preventDefault();
      return false;
    } else {
      return true;
    }
  }

  clearHighlights() {
    var highlight;
    highlight = new Hightlight();
    this.suggestionTargets.forEach((abstractorSuggestion) => {
      highlight.removeHighlightsFromSuggestion(abstractorSuggestion, true);
    });
  }
}