import { Controller } from "stimulus"

export default class Notes extends Controller {
  static targets = []

  initialize() {
    document.addEventListener('turbolinks:before-cache', () => {
      document.querySelectorAll('.provider-speciality-select2, .provider-select2, .abstraction-site-select2, .abstraction-histology-select2').forEach((select2) => {
        $(select2).select2();
        $(select2).select2('destroy');
      });

      document.querySelectorAll('.datepicker').forEach((datepicker) => {
        $(datepicker).datepicker();
        $(datepicker).datepicker('destroy');
      });
    })
  }

  connect() {
    var controller, abstractionSiteStatus, abstractionHistologyStatus;
    controller = this;

    document.querySelectorAll('.datepicker').forEach((datepicker) => {
      $(datepicker).datepicker({
        altFormat: "yy-mm-dd",
        dateFormat: "yy-mm-dd",
        changeMonth: true,
        changeYear: true
      });
    });

    var providersUrl;
    providersUrl = $('#providers_url').attr('href');
    $('.provider-select2').select2({
      ajax: {
        url: providersUrl,
        dataType: 'json',
        delay: 250,
        data: function(params) {
          return {
            q: params.term,
            page: params.page
          };
        },
        processResults: function(data, params) {
          var results;
          params.page = params.page || 1;
          results = $.map(data.users, function(obj) {
            obj.id = obj.provider_name;
            obj.text = obj.provider_name;
            return obj;
          });
          return {
            results: results,
            pagination: {
              more: params.page * 10 < data.total
            }
          };
        },
        cache: true
      },
      escapeMarkup: function(markup) {
        return markup;
      },
      minimumInputLength: 2
    });

    var providerSpecialtiesUrl;
    providerSpecialtiesUrl = $('#provider_specialties_url').attr('href');
    $('.provider-speciality-select2').select2({
      ajax: {
        url: providerSpecialtiesUrl,
        dataType: 'json',
        delay: 250,
        data: function(params) {
          return {
            q: params.term,
            page: params.page
          };
        },
        processResults: function(data, params) {
          var results;
          params.page = params.page || 1;
          results = $.map(data.users, function(obj) {
            obj.id = obj.concept_id;
            obj.text = obj.concept_name;
            return obj;
          });
          return {
            results: results,
            pagination: {
              more: params.page * 10 < data.total
            }
          };
        },
        cache: true
      },
      escapeMarkup: function(markup) {
        return markup;
      },
      minimumInputLength: 2
    });

    $('.abstraction-site-select2, .abstraction-histology-select2').select2();

    document.querySelector('#abstraction_site_status').addEventListener('change', function (event) {
      controller.toggleAbstractionSite(this.value);
    });

    abstractionSiteStatus = document.querySelector('#abstraction_site_status');
    controller.toggleAbstractionSite(abstractionSiteStatus.value);

    document.querySelector('#abstraction_histology_status').addEventListener('change', function (event) {
      controller.toggleAbstractionHistology(this.value);
    });

    abstractionHistologyStatus = document.querySelector('#abstraction_histology_status');
    controller.toggleAbstractionHistology(abstractionHistologyStatus.value);
  }

  toggleAbstractionSite (abstractionSiteStatus) {
    var controller;
    controller = this;

    switch(abstractionSiteStatus) {
      case 'all':
        controller.disableAbstractionSite();
        break;
      case 'accepted':
        controller.enableAbstractionSite();
        break;
      case 'accepted specific':
        controller.disableAbstractionSite();
        break;
      case 'accepted general':
        controller.disableAbstractionSite();
        break;
      case 'suggested':
        controller.enableAbstractionSite();
        break;
      case 'suggested specific':
        controller.disableAbstractionSite();
        break;
      case 'suggested general':
        controller.disableAbstractionSite();
        break;
      default:
        controller.disableAbstractionSite();
    }
  }

  disableAbstractionSite () {
    $('.abstraction-site-select2').prop("disabled", true);
  }

  enableAbstractionSite () {
    $('.abstraction-site-select2').prop("disabled", false);
  }

  toggleAbstractionHistology (abstractionHistologyStatus) {
    var controller;
    controller = this;

    switch(abstractionHistologyStatus) {
      case 'all':
        controller.disableAbstractionHistology();
        break;
      case 'accepted':
        controller.enableAbstractionHistology();
        break;
      case 'accepted specific':
        controller.disableAbstractionHistology();
        break;
      case 'accepted general':
        controller.disableAbstractionHistology();
        break;
      case 'suggested':
        controller.enableAbstractionHistology();
        break;
      case 'suggested specific':
        controller.disableAbstractionHistology();
        break;
      case 'suggested general':
        controller.disableAbstractionHistology();
        break;
      default:
        controller.disableAbstractionHistology();
    }
  }

  disableAbstractionHistology () {
    $('.abstraction-histology-select2').prop("disabled", true);
  }

  enableAbstractionHistology () {
    $('.abstraction-histology-select2').prop("disabled", false);
  }
}