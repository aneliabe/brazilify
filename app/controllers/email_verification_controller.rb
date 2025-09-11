class EmailVerificationController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    # This shows the "email sent" confirmation page
  end
end
