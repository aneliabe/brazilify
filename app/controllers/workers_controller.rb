class WorkersController < ApplicationController
  skip_before_action :authenticate_user!, only: :show

  def show
    # TEMP: mock until DB is ready
    @worker = WorkerProfile.includes(:services, :user).find(params[:id])
  end
end
