class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :search]

  def home
    @popular_services = Service.order("RANDOM()").limit(8)
    @top_workers = find_top_workers
  end

  def search
    raw_city = params[:city].to_s.strip
    @q = params[:q].to_s.strip

    city_token, _country_hint = parse_city_label(raw_city)

    scope = WorkerProfile
              .includes(:user, :services, :reviews)
              .joins(:user)

    scope = scope.where("LOWER(users.city) LIKE LOWER(?)", "%#{city_token}%") if city_token.present?
    scope = scope.joins(:services).where("services.name ILIKE ?", "%#{@q}%").distinct if @q.present?

    @workers = scope
  end

  private

  def find_top_workers
    target_city = get_target_city

    if target_city.present?
      workers_by_city(target_city)
    else
      random_workers
    end
  end

  def get_target_city
    search_city = params[:city].to_s.strip
    user_city = current_user&.city
    search_city.present? ? search_city : user_city
  end

  def workers_by_city(city)
    WorkerProfile
      .includes(:user, :services, :reviews)
      .joins(:user)
      .where("LOWER(users.city) LIKE LOWER(?)", "%#{city}%")
      .limit(6)
  end

  def random_workers
    WorkerProfile
      .includes(:user, :services, :reviews)
      .order("RANDOM()")
      .limit(6)
  end

  def parse_city_label(label)
    parts = label.split(",").map { |s| s.strip }.reject(&:blank?)
    return [nil, nil] if parts.empty?

    if parts.size == 1
      [parts[0], nil]
    else
      city = parts[-2].presence || parts[0]
      country = parts[-1]&.upcase
      [city, country]
    end
  end
end
