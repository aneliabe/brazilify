class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :full_name, :birth_date, :address, :city, :country, :country_code, :phone, :avatar
    ])

    devise_parameter_sanitizer.permit(:account_update, keys: [
      :full_name, :birth_date, :address, :city, :country, :country_code, :phone, :avatar
    ])
  end
end
