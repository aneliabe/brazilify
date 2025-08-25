class UsersController < ApplicationController
  before_action :authenticate_user! # ensure only logged-in users can view profiles
  skip_before_action :authenticate_user!, only: [:show]

  def show
  end

  def edit
  end

  def update
  end

  def become_worker
  end

  def activate_worker
    if current_user.update(user_params.merge(worker: true))
      redirect_to worker_users_path, notice: "Agora você pode oferecer os seus serviços!"
    else
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
end
