class ProviderSpecialtiesController < ApplicationController
  before_action :authenticate_user!

  def index
    params[:page]||= 1
    @all_provider_specialities = Concept.provider_specialties.search(params[:q])
    @provider_specialities = @all_provider_specialities.paginate(per_page: 10, page: params[:page])
    respond_to do |format|
        format.json {
          render json: {
            users: @provider_specialities,
            total: @all_provider_specialities.count,
            links: { self: @provider_specialities.current_page , next: @provider_specialities.next_page }
        }.to_json
      }
    end
  end
end