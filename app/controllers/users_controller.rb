class UsersController < ApplicationController
  before_action :authenticate_user! # ensure only logged-in users can view profiles
  skip_before_action :authenticate_user!, only: [:show]

  before_action :set_user, only: [:show, :become_worker, :activate_worker, :worker_dashboard]

  def show
  end

  def edit
  end

  def update
  end

  # GET /users/:id/become_worker
  def become_worker
    @categories = Category.all
    @worker_profile = @user.worker_profile || @user.build_worker_profile
    @service_types = Service.service_types.keys
  end

  # POST /users/:id/become_worker
  def activate_worker
    @worker_profile = @user.worker_profile || @user.build_worker_profile
    if @worker_profile.update(worker_profile_params)
      @user.update(worker: true)
      redirect_to worker_dashboard_user_path(@user), notice: "Agora você pode oferecer os seus serviços!"
    else
      @categories = Category.all
      @service_types = Service.service_types.keys
      render :become_worker, status: :unprocessable_entity
    end
  end

  def edit_worker
    render :become_worker
  end

  def worker_dashboard
    unless current_user.worker?
      redirect_to root_path, alert: "Acesso não autorizado"
      return
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def worker_profile_params
    params.require(:worker_profile).permit(:category_id, :service_id, :service_type)
  end
end


# class UsersController < ApplicationController
#   before_action :authenticate_user! # ensure only logged-in users can view profiles
#   skip_before_action :authenticate_user!, only: [:show]

#   def show
#   end

#   def edit
#   end

#   def update
#   end

#   def become_worker
#   end

#   def activate_worker
#     if current_user.update(user_params.merge(worker: true))
#       redirect_to worker_users_path, notice: "Agora você pode oferecer os seus serviços!"
#     else
#       render :become_worker, status: :unprocessable_entity
#     end
#   end

#   def edit_worker
#     render :become_worker
#   end

#   def worker_dashboard
#     unless current_user.worker?
#       redirect_to root_path, alert: "Acesso não autorizado"
#       return
#     end
#   end

#   private
#   def set_user
#     @user = User.find(params[:id])
#   end
# end
