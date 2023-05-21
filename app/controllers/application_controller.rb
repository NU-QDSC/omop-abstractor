class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end

  before_action :configure_permitted_parameters, if: :devise_controller?

  def abstractor_user
    current_user if defined?(current_user)
  end
  helper_method :abstractor_user

  def discard_redirect_to(params, about)
    request.env['HTTP_REFERER'] || root_path
  end

  def undiscard_redirect_to(params, about)
    request.env['HTTP_REFERER'] || root_path
  end

  def update_workflow_status_redirect_to(params, about)
    request.env['HTTP_REFERER'] || root_path
  end

  def back_from_note_edit
    session[:index_history] || notes_url
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  protected
    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_in) do |user_params|
        user_params.permit(:username, :email, :password)
      end

      devise_parameter_sanitizer.permit(:account_update) do |user_params|
        user_params.permit(:last_name, :first_name)
      end
    end

    def record_history
      session[:history] ||= nil
      session[:history] = request.url
    end
end