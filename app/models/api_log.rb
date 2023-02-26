class ApiLog < ApplicationRecord
  def self.create_api_log(url, payload, response, error, system)
    ApiLog.create!(
                  url: url,
                  payload: payload,
                  response: response,
                  error: error,
                  system: system
                  )
  end
end