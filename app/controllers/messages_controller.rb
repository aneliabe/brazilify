class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @appointment = Appointment.find(params[:appointment_id])
    return redirect_to root_path, alert: "You are not allowed to post here." unless @appointment.participant?(current_user)
    
    @message = Message.new(message_params)
    @message.appointment = @appointment
    @message.user = current_user

    if @message.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            :messages,
            partial: "messages/message",
            locals: { message: @message, user: current_user }
          )
        end
        format.html { redirect_to appointment_path(@appointment) }
      end
    else
      render "appointments/show", status: :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
