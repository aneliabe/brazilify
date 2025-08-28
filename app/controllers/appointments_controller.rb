class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: :show
  before_action :authorize_participant!, only: :show

  def create
    worker = WorkerProfile.find(params[:worker_id]) # from nested route
    @appointment = Appointment.new(appointment_params)
    @appointment.worker_profile = worker
    @appointment.user = current_user

    if @appointment.save
      redirect_to @appointment, notice: "Appointment created."
    else
      redirect_to worker_path(worker), alert: @appointment.errors.full_messages.to_sentence
    end
  end

  def show
    @appointment = Appointment.find(params[:id])
    @message = Message.new
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def authorize_participant!
    unless @appointment.participant?(current_user)
      redirect_to root_path, alert: "You are not allowed to access this chat."
    end
  end

  def appointment_params
    params.require(:appointment).permit(:starts_at, :ends_at)
  end
end
