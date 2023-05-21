import { Controller } from "stimulus";
import Hightlight from '../omop_abstractor/highlight';
const controllers = new Set([]);
export default class AbstractorSuggestionController extends Controller {
  static targets = ['suggestion', 'tooltip']

  initialize() {
  }

  connect() {
    controllers.add(this);
    this.highlightedRanges = [];
  }

  determine() {
    var controller, currentTarget, parentForm;
    controller = this;
    currentTarget = event.currentTarget;
    parentForm = currentTarget.closest("form");
    Rails.fire(parentForm, 'submit');
    return;
  }

  handleHighlight() {
    event.preventDefault();
    var highlight, target, tab, highlighted;
    highlight = new Hightlight();
    if (this.tooltipTarget) {
      target = this.tooltipTarget.attributes['rel'];
      tab = $(target.value).find('.abstractor_source_tab');
      if (tab.length === 1) {
        tab = $(tab).html().trim();
        $('#' + tab + ' input[type=radio]').prop('checked', true);
        if ($(this.tooltipTarget).hasClass('highlighted_suggestion')) {
          $(this.tooltipTarget).removeClass('highlighted_suggestion');
          highlight.clearAllHighlights();
        } else {
          highlighted = true;
          $('.highlighted_suggestion').removeClass('highlighted_suggestion');
          highlight.clearAllHighlights();
          $(this.tooltipTarget).addClass('highlighted_suggestion');
          highlight.highlight(this.suggestionTarget);
        }
      }
    }
  }
}