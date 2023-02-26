require 'rest_client'
class StudyTrackerApi
  SYSTEM = 'study tracker'

  def initialize
    @user = Rails.application.credentials.study_tracker[Rails.env.to_sym][:api_user]
    @password = Rails.application.credentials.study_tracker[Rails.env.to_sym][:password]

    if Rails.env.development? || Rails.env.test?
      @verify_ssl = Rails.application.credentials.study_tracker[Rails.env.to_sym][:verify_ssl]
    else
      @verify_ssl = true
    end
  end

  def authorized_personnel?(username)
    authorized_personnel = false
    url = Rails.application.credentials.study_tracker[Rails.env.to_sym][:user]
    irb_number = Rails.application.credentials.study_tracker[Rails.env.to_sym][:irb_number]
    url.gsub!(':username', username)
    api_response = study_tracker_api_request_wrapper(url: url, method: :get, parse_response: true)

    if api_response[:response].blank?
      authorized_personnel = false
    else
      authorized_personnel = api_response[:response]['study_roles'].any? { |study_role| study_role['irb_number'] == irb_number }
    end

    authorized_personnel
  end

  private
    def study_tracker_api_request_wrapper(options={})
      response = nil
      error =  nil
      begin
        case options[:method]
        when :get
          response = RestClient::Request.execute(
            method: options[:method],
            url: options[:url],
            user: @user,
            password: @password,
            accept: 'json',
            verify_ssl: @verify_ssl,
            headers: {
              content_type: 'application/json; charset=utf-8'
            }
          )
          ApiLog.create_api_log(options[:url], nil, response, nil, StudyTrackerApi::SYSTEM)
        else
           # payload = options[:payload].to_json
           payload = ActiveSupport::JSON.encode(options[:payload])
           options[:payload] = payload
           response = RestClient::Request.execute(
            method: options[:method],
            user: @user,
            password: @password,
            url: options[:url],
            payload: payload,
            # content_type:  'application/json',
            # accept: 'json',
            verify_ssl: @verify_ssl,
            headers: {
              content_type: 'application/json; charset=utf-8'
            }
          )
          ApiLog.create_api_log(options[:url], payload, response, nil, StudyTrackerApi::SYSTEM)
        end
        response = JSON.parse(response) if options[:parse_response]
        if response[:errors].present?
          error = response[:errors]
        end
      rescue Exception => e
        ExceptionNotifier.notify_exception(e)
        ApiLog.create_api_log(options[:url], options[:payload], nil, e.message, StudyTrackerApi::SYSTEM)
        error = e
        Rails.logger.info(e.class)
        Rails.logger.info(e.message)
        Rails.logger.info(e.backtrace.join("\n"))
      end

      { response: response, error: error }
    end
end