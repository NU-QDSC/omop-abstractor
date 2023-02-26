import { Controller } from "stimulus"

export default class AbstractorObjectValueVariantsController extends Controller {
  static targets =['list', 'template']

  connect() {
    if (typeof M.updateTextFields == 'function') {
      M.updateTextFields();
    }
  }

  add_association(event) {
    event.preventDefault();
    var content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime());
    this.listTarget.insertAdjacentHTML('beforeend', content);
  }

  remove_association(event) {
    event.preventDefault();
    let wrapper = event.target.closest('.abstractor-object-value-variant')
    if (wrapper.dataset.newRecord == "true"){
      wrapper.remove();
    }
    else {
      wrapper.querySelector("input[name*='_destroy']").value = 1;
      wrapper.style.display = 'none';
    }
  }
}