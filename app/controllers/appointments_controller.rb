class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: [:show, :accept, :decline]
  before_action :authorize_participant!, only: :show
  before_action :authorize_worker!, only: [:accept, :decline]

  # /my/appointments (optionally filtered by ?as=worker|client&status=pending|accepted|declined)
  def index
    base = Appointment.joins(:worker_profile).includes(:messages, :user, worker_profile: :user)

    case params[:as]
    when "worker"   # I’m the professional (owner of the worker_profile)
      @appointments = base.where(worker_profiles: { user_id: current_user.id })
    when "client"   # I’m the requester
      @appointments = base.where(appointments: { user_id: current_user.id })
    else            # both roles
      @appointments = base.where(
        "appointments.user_id = :uid OR worker_profiles.user_id = :uid",
        uid: current_user.id
      )
    end

    @appointments = @appointments.where(status: params[:status]) if params[:status].present?
    @appointments = @appointments.order(created_at: :desc)
  end

  # POST /workers/:worker_id/appointments
  def create
    worker = WorkerProfile.find(params[:worker_id]) # nested route
    @appointment = Appointment.new(appointment_params)
    @appointment.worker_profile = worker
    @appointment.user = current_user
    @appointment.status = "pending" if @appointment.status.blank?

    if @appointment.save
      # optional first message seeded from the modal textarea
      Message.create!(
        appointment: @appointment,
        user: current_user,
        content: params[:message]
      ) if params[:message].present?

      redirect_to @appointment, notice: "Solicitação criada. Conversem por aqui para alinhar detalhes."
    else
      redirect_to worker_path(worker), alert: @appointment.errors.full_messages.to_sentence
    end
  end

  # GET /appointments/:id
  def show
  @message = Message.new
    if current_user.id == @appointment.user_id
      @appointment.update_column(:client_last_read_at, Time.current)
    else
      @appointment.update_column(:worker_last_read_at, Time.current)
    end
  end

  # PATCH /appointments/:id/accept   (worker only)
  def accept
    accepted_for_worker = Appointment.joins(:worker_profile)
                                    .where(worker_profiles: { user_id: current_user.id }, status: "accepted")
                                    .where.not(id: @appointment.id)
    conflicts = accepted_for_worker.select { |a| overlap?(@appointment, a) }

    @appointment.update!(status: "accepted")

    # ✅ auto message into the chat
    tstr = @appointment.starts_at ? I18n.l(@appointment.starts_at, format: :short) : "sem data"
    Message.create!(appointment: @appointment, user: current_user,
                    content: "Agendamento ACEITO para #{tstr}. Vamos confirmar os detalhes por aqui.")

    msg = "Agendamento aceito."
    msg << " Atenção: há conflito com #{conflicts.size} agendamento(s) aceito(s)." if conflicts.any?
    redirect_back fallback_location: my_appointments_path(as: "worker"), notice: msg
  end

  def decline
    reason = params[:reason].to_s.strip
    @appointment.update!(status: "declined")

    tstr = @appointment.starts_at ? I18n.l(@appointment.starts_at, format: :short) : "sem data"
    content = "Agendamento RECUSADO para #{tstr}."
    content += " Motivo: #{reason}" if reason.present?

    Message.create!(appointment: @appointment, user: @appointment.worker_profile.user, content: content)

    redirect_back fallback_location: my_appointments_path(as: "worker"), notice: "Agendamento recusado."
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

  def authorize_worker!
    unless @appointment.worker_profile.user_id == current_user.id
      redirect_to root_path, alert: "Somente o profissional pode realizar esta ação."
    end
  end

  # start-only: user picks just day+time
  def appointment_params
    params.require(:appointment).permit(:starts_at)
  end

  # Treat no ends_at as 1h window for conflict detection
  def overlap?(a, b)
    a_start = a.starts_at
    a_end   = a.ends_at || (a.starts_at + 1.hour)
    b_start = b.starts_at
    b_end   = b.ends_at || (b.starts_at + 1.hour)
    (a_start < b_end) && (b_start < a_end)
  end
end
