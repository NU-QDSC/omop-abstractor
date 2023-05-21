class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :load_user, only: :show

  def show
    # authorize @user
  end

  private
    def load_user
      @user = User.find(params[:id])
    end
end