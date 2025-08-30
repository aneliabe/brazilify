class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :search]

  def home
    @popular_services = Service.order("RANDOM()").limit(8)
    @top_workers = WorkerProfile
      .includes(:user, :services, :reviews)
      .order("RANDOM()")
      .limit(6)
  end

  def search
    raw_city = params[:city].to_s.strip
    @q       = params[:q].to_s.strip

    city_token, _country_hint = parse_city_label(raw_city)

    scope = WorkerProfile
              .includes(:user, :services, :reviews) # optional, for ratings
              .joins(:user)

    scope = scope.where("users.city LIKE ?", "%#{city_token}%") if city_token.present?
    scope = scope.joins(:services).where("services.name ILIKE ?", "%#{@q}%").distinct if @q.present?

    @workers = scope
  end

  private

  # Accepts:
  #   "Dublin, IE"                  -> ["Dublin", "IE"]
  #   "Douglas, Cork, IE" (future)  -> ["Cork", "IE"]  # we search by the city only
  #   "Cork"                        -> ["Cork", nil]
  def parse_city_label(label)
    parts = label.split(",").map { |s| s.strip }.reject(&:blank?)
    return [nil, nil] if parts.empty?

    if parts.size == 1
      [parts[0], nil]
    else
      # Take the penultimate token as the city;
      # this covers both "City, CC" (city at index 0 == -2)
      # and "Neighborhood, City, CC" (city at index -2)
      city    = parts[-2].presence || parts[0]
      country = parts[-1]&.upcase
      [city, country]
    end
  end
end
