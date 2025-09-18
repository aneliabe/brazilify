class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :search]

  def home
    @popular_services = Service.popular_services
    @top_workers = find_top_workers
    @categories = Category.includes(:services).order(:name)
  end

  def search
    raw_city    = params[:city].to_s.strip
    @q          = params[:q].to_s.strip
    @category_id = params[:category_id].to_s.strip
    @service_id  = params[:service_id].to_s.strip
    @lat = params[:lat].present? ? params[:lat].to_f : nil
    @lng = params[:lng].present? ? params[:lng].to_f : nil

    if raw_city == "cache"
      @check_cache = true
      city_token = ""
    else
      city_token, _country_hint = parse_city_label(raw_city)
    end

    scope = WorkerProfile.includes(:user, :services, :reviews).joins(:user)

    has_location =
      city_token.present? ||
      (@lat && @lng && @lat != 0 && @lng != 0) ||
      current_user&.city.present?

    if !has_location
      @workers = WorkerProfile.none.page(params[:page]).per(9)
    else
      if @lat && @lng && @lat != 0 && @lng != 0
        radius_km = 50
        scope = scope.where(
          "users.latitude IS NOT NULL AND users.longitude IS NOT NULL AND
          (6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) *
          cos(radians(users.longitude) - radians(?)) +
          sin(radians(?)) * sin(radians(users.latitude)))) <= ?",
          @lat, @lng, @lat, radius_km
        )
      elsif current_user&.latitude && current_user&.longitude
        radius_km = 50
        scope = scope.where(
          "users.latitude IS NOT NULL AND users.longitude IS NOT NULL AND
          (6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) *
          cos(radians(users.longitude) - radians(?)) +
          sin(radians(?)) * sin(radians(users.latitude)))) <= ?",
          current_user.latitude, current_user.longitude, current_user.latitude, radius_km
        )
      else
        target_city = city_token.present? ? city_token : current_user&.city
        scope = scope.where("LOWER(users.city) LIKE LOWER(?)", "%#{target_city}%") if target_city.present?
      end

      if @service_id.present?
        scope = scope.joins(:services).where(services: { id: @service_id }).distinct
      elsif @q.present?
        scope = scope.joins(:services).where("services.name ILIKE ?", "%#{@q}%").distinct
      end

      if @category_id.present?
        scope = scope.joins(:services).where(services: { category_id: @category_id }).distinct
      end

      @workers = scope.page(params[:page]).per(9)
    end

    @categories = Category.includes(:services).order(:name)
  end

  private

  def find_top_workers
    if current_user
      find_workers_by_location(current_user)
    else
      target_city = params[:city].to_s.strip
      target_city.present? ? find_workers_by_location(target_city) : random_workers
    end
  end

  def get_target_city
    search_city = params[:city].to_s.strip
    user_city = current_user&.city
    search_city.present? ? search_city : user_city
  end

  def workers_by_city(city)
    find_workers_by_location(city)
  end

  def find_workers_by_location(user_or_city, limit: 6)
    scope = WorkerProfile.includes(:user, :services, :reviews).joins(:user)

    if user_or_city.is_a?(User) && user_or_city.latitude && user_or_city.longitude
      radius_km = 50
      scope = scope.where(
        "users.latitude IS NOT NULL AND users.longitude IS NOT NULL AND
         (6371 * acos(cos(radians(?)) * cos(radians(users.latitude)) *
         cos(radians(users.longitude) - radians(?)) +
         sin(radians(?)) * sin(radians(users.latitude)))) <= ?",
        user_or_city.latitude, user_or_city.longitude, user_or_city.latitude, radius_km
      )
    elsif user_or_city.is_a?(String)
      scope = scope.where("LOWER(users.city) LIKE LOWER(?)", "%#{user_or_city}%")
    elsif user_or_city.is_a?(User)
      scope = scope.where("LOWER(users.city) LIKE LOWER(?)", "%#{user_or_city.city}%") if user_or_city.city
    end

    scope.order("RANDOM()").limit(limit)
  end

  def random_workers
    WorkerProfile.includes(:user, :services, :reviews).order("RANDOM()").limit(6)
  end

  def parse_city_label(label)
    parts = label.split(",").map(&:strip).reject(&:blank?)
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
