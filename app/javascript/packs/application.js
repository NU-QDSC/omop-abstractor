/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

import _ from 'lodash';
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.js$/)
application.load(definitionsFromContext(context))

document.addEventListener('turbolinks:load', () => {
  var sidenavs = document.querySelectorAll('.sidenav');
  M.Sidenav.init(sidenavs, { edge: 'right' });

  var selects = document.querySelectorAll('select');
  M.FormSelect.init(selects, {});

  M.Modal._count = 0;
  var modals = document.querySelectorAll('.modal');
  M.Modal.init(modals, {});

  if ($('.abstractor_footer').length > 0) {
    $('.abstractor_abstractions').css('margin-top', $('.abstractor_footer').height() * -1);
  }
  M.updateTextFields();
});

document.addEventListener('turbolinks:before-cache', () => {
  $('.sidenav').sidenav('destroy');
  document.querySelectorAll('select').forEach((select) => {
    var instance = M.FormSelect.getInstance(select);
    if (instance) {
      instance.destroy();
    }
  });

  document.querySelectorAll('.modal').forEach((modal) => {
    var instance = M.Modal.getInstance(modal);
    if (instance) {
      instance.destroy();
    }
  });
});