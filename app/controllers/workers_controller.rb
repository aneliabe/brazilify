class WorkersController < ApplicationController
  before_action :authenticate_user!, only: :contact
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @city = params[:city].to_s.strip
    @svc  = params[:service_id].to_s

    @filters_applied = @city.present? || @svc.present?

    @services = Service.order(:name) # for the select

    scope = WorkerProfile.includes(:user, :services)

    if @city.present?
      scope = scope.joins(:user)
                 .where("LOWER(users.city) LIKE ?", "%#{@city.downcase}%")
    end

    if @svc.present?
      scope = scope.joins(:services)
                  .where(services: { id: @svc })
                  .distinct
    end

    @workers = scope.order("users.full_name ASC").references(:user)
  end

  # Clients can only click be redirected to the contact if logged in.
  def contact
    @worker = User.find(params[:id])
    render :contact
  end

  def show
    # TEMP: mock until DB is ready
    @worker = WorkerProfile.includes(:user, :services, reviews: :user).find(params[:id])
    @appointment = Appointment.new
    @appointments = @worker.appointments.where(user: current_user)
    @user = @worker.user
  end
end
