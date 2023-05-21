require 'rest_client'
class RedcapApi
  ERROR_MESSAGE_DUPLICATE_PATIENT = 'More than one patient with record_id.'
  attr_accessor :api_token, :api_url, :system
  SYSTEM_REDCAP = 'redcap'

  def initialize(project_name)
    @api_token = Rails.application.credentials.redcap[project_name.to_sym][Rails.env.to_sym][:api_token]
    @system = SYSTEM_REDCAP

    @api_url = Rails.application.credentials.redcap[project_name.to_sym][Rails.env.to_sym][:api_url]
    if Rails.env.development? || Rails.env.test?
      @verify_ssl = Rails.application.credentials.redcap[project_name.to_sym][Rails.env.to_sym][:verify_ssl]
    else
      @verify_ssl = true
    end
  end

  def patients
    payload = {
        :token => @api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        'fields[0]' => 'case_number',
        'fields[1]' => 'nmhc_mrn',
        'fields[2]' => 'record_id',
        :returnFormat => 'json'
    }

    api_response = redcap_api_request_wrapper(payload)

    { response: api_response[:response], error: api_response[:error] }
  end

  def patients_nu_chers
    payload = {
        :token => @api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        'fields[0]' => 'dem_case_num',
        'fields[1]' => 'dem_case_num',
        'fields[1]' => 'record_id',
        :returnFormat => 'json'
    }

    api_response = redcap_api_request_wrapper(payload)

    { response: api_response[:response], error: api_response[:error] }
  end

  def next_record_id
    payload = {
      :token => @api_token,
      :content => 'record',
      :format => 'json',
      :type => 'flat',
      'fields[0]' => 'record_id',
      :returnFormat => 'json'
    }

    api_response = redcap_api_request_wrapper(payload)
    record_id = api_response[:response].map { |r| r['record_id'].to_i }.max
    record_id+=1

    { response: record_id, error: api_response[:error] }
  end

  def update_prostate_spore_surgery(record_id, diagnosis, surgery_date, surgery_type, surgical_pathology_number, pathological_staging_t, pathological_staging_n, pathological_staging_m, surgery_prostate_weight, nervesparing_procedure, extra_capsular_extension, margins, seminal_vesicle, lymph_nodes, lymphatic_vascular_invasion, surgery_perineural, surgery_gleason_1, surgery_gleason_2, surgery_gleason_tertiary, surgery_precentage_of_prostate_cancer_tissue)
    surgery_date = Date.parse(surgery_date) if surgery_date
    puts 'before the API call'

    if surgery_prostate_weight == 'not applicable'
      surgery_prostate_weight = nil
    end

    payload = {
        :token => @api_token,
        :content => 'record',
        :format => 'csv',
        :type => 'flat',
        :overwriteBehavior => 'overwrite',
        :data => %(record_id,diagnosis,surgery_date,surgery_type,surgical_pathology_number,pathological_staging_t,pathological_staging_n,pathological_staging_m,surgery_prostate_weight,nervesparing_procedure,extra_capsular_extension,margins,seminal_vesicle,lymph_nodes,lymphatic_vascular_invasion,surgery_perineural,surgery_gleason_1,surgery_gleason_2,surgery_gleason_tertiary,surgery_precentage_of_prostate_cancer_tissue,surgery_complete
  "#{record_id}","#{diagnosis}","#{surgery_date}","#{surgery_type}","#{surgical_pathology_number}","#{pathological_staging_t}","#{pathological_staging_n}","#{pathological_staging_m}","#{surgery_prostate_weight}","#{nervesparing_procedure}","#{extra_capsular_extension}","#{margins}","#{seminal_vesicle}","#{lymph_nodes}","#{lymphatic_vascular_invasion}","#{surgery_perineural}","#{surgery_gleason_1}","#{surgery_gleason_2}","#{surgery_gleason_tertiary}","#{surgery_precentage_of_prostate_cancer_tissue}","1"),
        :returnContent => 'ids',
        :returnFormat => 'json'
      }

    api_response = redcap_api_request_wrapper(payload)

    puts 'after the api call'
    { response: record_id, error: api_response[:error] }
  end
  # biopsy_date, biopsy_reported_by, biopsy_result, biopsy_total_cores, biopsy_positive_cores, biopsy_gleason_1, biopsy_gleason_2, biopsy_gleason_tertiary, biopsy_involving_percentage_of_prostate_tissue, biopsy_perineural_invasion, biopsies_complete

  def update_prostate_spore_biopsy(record_id, redcap_repeat_instance, biopsy_pathology_number, biopsy_date, biopsy_reported_by, biopsy_result, biopsy_total_cores, biopsy_positive_cores, biopsy_gleason_1, biopsy_gleason_2, biopsy_gleason_tertiary, biopsy_involving_percentage_of_prostate_tissue, biopsy_perineural_invasion, biopsies_complete)
    biopsy_date = Date.parse(biopsy_date) if biopsy_date
    biopsy_total_cores = nil
    biopsy_positive_cores = nil
    puts 'before the API call'

    payload = {
        :token => @api_token,
        :content => 'record',
        :format => 'csv',
        :type => 'flat',
        :overwriteBehavior => 'overwrite',
        :data => %(record_id,redcap_repeat_instrument,redcap_repeat_instance,biopsy_pathology_number,biopsy_date,biopsy_reported_by,biopsy_result,biopsy_total_cores,biopsy_positive_cores,biopsy_gleason_1,biopsy_gleason_2,biopsy_gleason_tertiary,biopsy_involving_percentage_of_prostate_tissue,biopsy_perineural_invasion,biopsies_complete
  "#{record_id}","biopsies","#{redcap_repeat_instance}","#{biopsy_pathology_number}","#{biopsy_date}","#{biopsy_reported_by}","#{biopsy_result}","#{biopsy_total_cores}","#{biopsy_positive_cores}","#{biopsy_gleason_1}","#{biopsy_gleason_2}","#{biopsy_gleason_tertiary}","#{biopsy_involving_percentage_of_prostate_tissue}","#{biopsy_perineural_invasion}","#{biopsies_complete}"),
        :returnContent => 'ids',
        :returnFormat => 'json'
      }

    api_response = redcap_api_request_wrapper(payload)

    puts 'after the api call'
    { response: record_id, error: api_response[:error] }
  end

  def prostate_spore_biopsies(record_id)
    payload = {
        :token => @api_token,
        :content => 'record',
        :format => 'json',
        :type => 'flat',
        'records[0]' => "#{record_id}",
        'fields[0]' => 'record_id',
        'forms[0]' => 'biopsies',
        :returnFormat => 'json'
    }

    api_response = redcap_api_request_wrapper(payload)
    redcap_repeat_instance = api_response[:response].map { |r| r['redcap_repeat_instance'].to_i }.max
    redcap_repeat_instance+=1
    { response: api_response[:response], error: api_response[:error], redcap_repeat_instance: redcap_repeat_instance }
  end

  def update_nu_chers_baseline_demographics(record_id, add_bl_disease_site___cervix, add_bl_disease_site___endometrium, add_bl_disease_site___ovary, add_bl_disease_site___uterus, add_bl_disease_site___vulva, add_bl_disease_site___vagina, add_bl_disease_site___adnexa, add_bl_disease_site___peritoneal_cavity, add_bl_disease_site___9999)
    puts 'before the API call'

    payload = {
        :token => @api_token,
        :content => 'record',
        :format => 'csv',
        :type => 'flat',
        :overwriteBehavior => 'overwrite',
        :data => %(record_id,add_bl_disease_site___cervix,add_bl_disease_site___endometrium,add_bl_disease_site___ovary,add_bl_disease_site___uterus,add_bl_disease_site___vulva,add_bl_disease_site___vagina,add_bl_disease_site___adnexa,add_bl_disease_site___peritoneal_cavity,add_bl_disease_site___9999
  "#{record_id}","#{add_bl_disease_site___cervix}","#{add_bl_disease_site___endometrium}","#{add_bl_disease_site___ovary}","#{add_bl_disease_site___uterus}","#{add_bl_disease_site___vulva}","#{add_bl_disease_site___vagina}","#{add_bl_disease_site___adnexa}","#{add_bl_disease_site___peritoneal_cavity}","#{add_bl_disease_site___9999}"),
        :returnContent => 'ids',
        :returnFormat => 'json'
      }

    api_response = redcap_api_request_wrapper(payload)

    puts 'after the api call'
    { response: record_id, error: api_response[:error] }
  end

  private
    def redcap_api_request_wrapper(payload, parse_response = true)
      response = nil
      error =  nil
      begin
        puts 'beging payload'
        puts payload
        puts 'end payload'
        response = RestClient::Request.execute(
          method: :post,
          url: @api_url,
          payload: payload,
          content_type:  'application/json',
          accept: 'json',
          verify_ssl: @verify_ssl
        )

        # ApiLog.create_api_log(@api_url, payload, response, nil, @system)
        response = JSON.parse(response) if parse_response
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        puts 'kaboom!'
        # ApiLog.create_api_log(@api_url, payload, nil, e.message, @system)
        error = e
        Rails.logger.info(e.class)
        Rails.logger.info(e.message)
        Rails.logger.info(e.backtrace.join("\n"))
      end
      { response: response, error: error }
    end
end