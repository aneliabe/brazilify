class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_inactive_sign_up_path_for(resource)
    # This redirects to your custom page after signup
    email_verification_path
  end
end
