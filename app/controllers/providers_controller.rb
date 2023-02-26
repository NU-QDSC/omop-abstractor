class ProvidersController < ApplicationController
  before_action :authenticate_user!

  def index
    params[:page]||= 1
    @all_providers = Provider.search(params[:q])
    @providers = @all_providers.paginate(per_page: 10, page: params[:page])
    respond_to do |format|
        format.json {
          render json: {
            users: @providers,
            total: @all_providers.count,
            links: { self: @providers.current_page , next: @providers.next_page }
        }.to_json
      }
    end
  end
end