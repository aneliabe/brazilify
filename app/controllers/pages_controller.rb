class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :search]

  def home
    @popular_services = Service.popular_services
    @top_workers = find_top_workers
    @categories = Category.includes(:services).order(:name)
  end

def search
  raw_city = params[:city].to_s.strip
  @q = params[:q].to_s.strip
  @category_id = params[:category_id].to_s.strip
  @service_id = params[:service_id].to_s.strip

  # If city is "cache", let JavaScript handle it by rendering the page first
  if raw_city == "cache"
    @check_cache = true
    city_token = ""  # Don't parse "cache" as a city
  else
    city_token, _country_hint = parse_city_label(raw_city)
  end

  scope = WorkerProfile
            .includes(:user, :services, :reviews)
            .joins(:user)

  # CRITICAL: For non-logged users, require city or return empty results
  if !user_signed_in? && city_token.blank?
    @workers = WorkerProfile.none  # Return empty scope whether checking cache or not
  else
    # Apply city filter (either from params or from logged user)
    target_city = city_token.present? ? city_token : current_user&.city
    scope = scope.where("LOWER(users.city) LIKE LOWER(?)", "%#{target_city}%") if target_city.present?

    # Apply service filters - UPDATED LOGIC
    if @service_id.present?
      # Exact service match (from popular services)
      scope = scope.joins(:services)
                  .where(services: { id: @service_id })
                  .distinct
    elsif @q.present?
      # Text-based service search (from manual search)
      scope = scope.joins(:services)
                  .where("services.name ILIKE ?", "%#{@q}%")
                  .distinct
    end

    if @category_id.present?
      scope = scope.joins(:services)
                  .where(services: { category_id: @category_id })
                  .distinct
    end

    @workers = scope
  end

  @categories = Category.includes(:services).order(:name)
end

  private

  def find_top_workers
    target_city = get_target_city
    target_city.present? ? workers_by_city(target_city) : random_workers
  end

  def get_target_city
    search_city = params[:city].to_s.strip
    user_city = current_user&.city
    search_city.present? ? search_city : user_city
  end

  def get_search_city(city_token)
    city_token.present? ? city_token : current_user&.city
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
