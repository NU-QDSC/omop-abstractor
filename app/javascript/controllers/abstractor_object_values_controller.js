import { Controller } from "stimulus"

export default class AbstractorObjectValuesController extends Controller {
  static targets =[]

  connect() {
    if (typeof M.updateTextFields == 'function') {
       M.updateTextFields();
    }
  }
}