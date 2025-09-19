class UsersController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:show]
  before_action :set_user, only: [:show, :become_worker, :activate_worker, :edit_worker, :update_worker, :worker_dashboard, :edit_profile, :update_profile]

  def edit_profile
  end

  def update_profile
    if @user.update(user_params)
      redirect_to profile_user_path(@user), notice: "Perfil atualizado com sucesso!"
    else
      render :edit_profile
    end
  end

  def show
  end

  def become_worker
    @categories = Category.all
    @worker_profile = @user.worker_profile || @user.build_worker_profile
    @service_types = WorkerService.service_types.keys
  end

  def activate_worker
    save_worker_profile("Ativar perfil de prestador")
  end

  def worker_dashboard
    unless @user.worker?
      redirect_to root_path, alert: "Acesso não autorizado"
      return
    end

    @worker_profile = @user.worker_profile
    @worker_services = @worker_profile.worker_services.includes(:category, :service)

    # @worker_services = @worker_profile.worker_services.includes(:category, :service)
  end


  def edit_worker
    @categories = Category.all
    @worker_profile = @user.worker_profile
    @service_types = WorkerService.service_types.keys

    # @worker_profile.worker_services = []

    # render :become_worker
  end

  def update_worker
    save_worker_profile("Atualizar informações")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def worker_profile_params
    params.require(:worker_profile).permit(
      :cpf, :description,
      services_photos: [],
      worker_services_attributes: [:id, :category_id, :service_id, :service_type, :_destroy]
    )
  end

  def user_params
  params.require(:user).permit(
    :full_name,
    :birth_date,
    :address,
    :city,
    :country,
    :country_code,
    :phone,
    :email
  )
  end

  def save_worker_profile(submit_text)
    @categories = Category.all
    @service_types = WorkerService.service_types.keys
    @worker_profile = @user.worker_profile || @user.build_worker_profile

    if @worker_profile.update(worker_profile_params)
      @user.update(role: :worker) unless @user.worker?
      redirect_to worker_user_path(@user), notice: "#{submit_text} com sucesso!"
    else
      render :become_worker, status: :unprocessable_entity
    end
  end
end
