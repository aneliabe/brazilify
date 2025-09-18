class WorkersController < ApplicationController
  before_action :authenticate_user!, only: :contact
  skip_before_action :authenticate_user!, only: [:index, :show]

  def index
    @city = params[:city].to_s.strip
    @svc  = params[:service_id].to_s
    @lat = params[:lat].present? ? params[:lat].to_f : nil
    @lng = params[:lng].present? ? params[:lng].to_f : nil

    @filters_applied = @city.present? || @svc.present?
    @services = Service.order(:name) # for the select

    scope = WorkerProfile.includes(:user, :services).joins(:user)

    # Apply location filter - prefer coordinates over city names
    if @lat && @lng && @lat != 0 && @lng != 0
      # Use coordinate-based search
      radius_km = 50
      scope = scope.where(
        "users.latitude IS NOT NULL AND users.longitude IS NOT NULL AND
         (6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) *
         cos(radians(users.longitude) - radians(?)) +
         sin(radians(?)) * sin(radians(users.latitude)))) <= ?",
        @lat, @lng, @lat, radius_km
      )
    elsif @city.present?
      # Fallback to city name search
      scope = scope.where("LOWER(users.city) LIKE ?", "%#{@city.downcase}%")
    elsif current_user&.latitude && current_user&.longitude
      # Use logged user's coordinates
      radius_km = 50
      scope = scope.where(
        "users.latitude IS NOT NULL AND users.longitude IS NOT NULL AND
         (6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) *
         cos(radians(users.longitude) - radians(?)) +
         sin(radians(?)) * sin(radians(users.latitude)))) <= ?",
        current_user.latitude, current_user.longitude, current_user.latitude, radius_km
      )
    elsif current_user&.city
      # Use logged user's city as fallback
      scope = scope.where("LOWER(users.city) LIKE ?", "%#{current_user.city.downcase}%")
    end

    if @svc.present?
      scope = scope.joins(:services).where(services: { id: @svc }).distinct
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
