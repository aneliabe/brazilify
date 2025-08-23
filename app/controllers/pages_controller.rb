class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home ]

  def home
    # real services for the chips
    @popular_services = Service.order("RANDOM()").limit(8)

    # real workers for the cards
    @top_workers = WorkerProfile
      .includes(:user, :services)
      .order("RANDOM()")
      .limit(6)
  end

  def search
    @city = params[:city].to_s.strip
    @q    = params[:q].to_s.strip

    scope = WorkerProfile.includes(:user, :services)

    # filter by city (on users table)
    if @city.present?
      scope = scope.joins(:user)
                   .where("LOWER(users.city) LIKE ?", "%#{@city.downcase}%")
    end

    # filter by service name
    if @q.present?
      scope = scope.joins(:services)
                   .where("LOWER(services.name) LIKE ?", "%#{@q.downcase}%")
                   .distinct
    end

    @workers = scope
  end
end
