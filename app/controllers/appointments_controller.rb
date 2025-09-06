class AppointmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_appointment, only: [:show, :accept, :decline, :propose_time, :accept_proposed, :decline_proposed]
  before_action :authorize_participant!, only: [:show, :propose_time, :accept_proposed, :decline_proposed]
  before_action :authorize_worker!, only: [:accept, :decline]

  # /my/appointments (optionally filtered by ?as=worker|client&status=pending|accepted|declined)
  def index
    base = Appointment.joins(:worker_profile)
                      .includes(:messages, :user, worker_profile: :user)

    case params[:as]
    when "worker"
      role_scope = base.where(worker_profiles: { user_id: current_user.id })
    when "client"
      role_scope = base.where(appointments: { user_id: current_user.id })
    else
      role_scope = base.where("appointments.user_id = :uid OR worker_profiles.user_id = :uid", uid: current_user.id)
    end

    @counts_by_status = role_scope.group(:status).count
    @counts_by_status["pending"]  ||= 0
    @counts_by_status["accepted"] ||= 0
    @counts_by_status["declined"] ||= 0

    @appointments = role_scope
    @appointments = @appointments.where(status: params[:status]) if params[:status].present?
    @appointments = @appointments.order(created_at: :desc)
  end

  # POST /workers/:worker_id/appointments
  def create
    worker = WorkerProfile.find(params[:worker_id]) # nested route
    if current_user.id == worker.user_id
      redirect_to worker_path(worker), alert: "Você não pode agendar consigo mesmo." and return
    end

    @appointment = Appointment.new(appointment_params)
    @appointment.worker_profile = worker
    @appointment.user = current_user
    @appointment.status = "pending" if @appointment.status.blank?

    if @appointment.save
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
    # mark as read for unread indicator
    if current_user.id == @appointment.user_id
      @appointment.update_column(:client_last_read_at, Time.current) if @appointment.respond_to?(:client_last_read_at)
    else
      @appointment.update_column(:worker_last_read_at, Time.current) if @appointment.respond_to?(:worker_last_read_at)
    end
  end

  # PATCH /appointments/:id/accept   (worker only)
  def accept
    accepted_for_worker = Appointment.joins(:worker_profile)
                                     .where(worker_profiles: { user_id: current_user.id }, status: "accepted")
                                     .where.not(id: @appointment.id)
    conflicts = accepted_for_worker.select { |a| overlap?(@appointment, a) }

    @appointment.update!(status: "accepted")

    tstr = @appointment.starts_at ? I18n.l(@appointment.starts_at, format: :short) : "sem data"
    Message.create!(appointment: @appointment, user: current_user,
                    content: "Agendamento ACEITO para #{tstr}. Vamos confirmar os detalhes por aqui.")

    msg = "Agendamento aceito."
    msg << " Atenção: há conflito com #{conflicts.size} agendamento(s) aceito(s)." if conflicts.any?
    redirect_back fallback_location: my_appointments_path(as: "worker"), notice: msg
  end

  # PATCH /appointments/:id/decline  (worker only)
  def decline
    @appointment.update!(status: "declined")

    tstr = @appointment.starts_at ? I18n.l(@appointment.starts_at, format: :short) : "sem data"
    Message.create!(appointment: @appointment, user: @appointment.worker_profile.user,
                    content: "Agendamento RECUSADO para #{tstr}. Motivo: (opcional).")

    redirect_back fallback_location: my_appointments_path(as: "worker"), notice: "Agendamento recusado."
  end

  # ---------- RESCHEDULE: propose/accept/decline ----------

  # POST /appointments/:id/propose_time
  def propose_time
    new_time_str = params[:proposed_starts_at].to_s.strip
    new_time = (Time.zone.parse(new_time_str) rescue nil)

    if new_time.blank? || new_time < Time.current
      return redirect_back fallback_location: appointment_path(@appointment),
                           alert: "Escolha um horário válido no futuro."
    end

    @appointment.update!(proposed_starts_at: new_time, proposed_by: current_user)

    Message.create!(
      appointment: @appointment,
      user: current_user,
      content: "Propus novo horário: #{I18n.l(new_time, format: :short)}"
    )

    redirect_to appointment_path(@appointment), notice: "Proposta enviada. Aguarde a resposta."
  end

  # PATCH /appointments/:id/accept_proposed
  def accept_proposed
    unless @appointment.proposed_starts_at.present?
      return redirect_back fallback_location: appointment_path(@appointment),
                           alert: "Não há proposta pendente."
    end
    if @appointment.proposed_by_id == current_user.id
      return redirect_back fallback_location: appointment_path(@appointment),
                           alert: "Quem propôs não pode aceitar. Aguarde a outra parte."
    end
    if @appointment.proposed_starts_at < Time.current
      return redirect_back fallback_location: appointment_path(@appointment),
                           alert: "A proposta já passou. Envie uma nova."
    end

    # Conflict warning only matters to the worker when they accept
    warning = nil
    if current_user.id == @appointment.worker_profile.user_id
      accepted_for_worker = Appointment.joins(:worker_profile)
                                       .where(worker_profiles: { user_id: current_user.id }, status: "accepted")
                                       .where.not(id: @appointment.id)
      conflicts = accepted_for_worker.select { |a| overlap_open_end?(@appointment.proposed_starts_at, a) }
      warning = " Atenção: conflito com #{conflicts.size} agendamento(s) aceito(s)." if conflicts.any?
    end

    @appointment.update!(
      starts_at: @appointment.proposed_starts_at,
      proposed_starts_at: nil,
      proposed_by_id: nil,
      status: (@appointment.status == "pending" ? "accepted" : @appointment.status)
    )

    Message.create!(
      appointment: @appointment,
      user: current_user,
      content: "Proposta ACEITA. Novo horário: #{I18n.l(@appointment.starts_at, format: :short)}."
    )

    notice = "Horário atualizado." + (warning || "")
    redirect_to appointment_path(@appointment), notice: notice
  end

  # PATCH /appointments/:id/decline_proposed
  def decline_proposed
    unless @appointment.proposed_starts_at.present?
      return redirect_back fallback_location: appointment_path(@appointment),
                           alert: "Não há proposta pendente."
    end
    if @appointment.proposed_by_id == current_user.id
      return redirect_back fallback_location: appointment_path(@appointment),
                           alert: "Quem propôs não pode recusar. Proponha outro horário."
    end

    old = @appointment.proposed_starts_at
    @appointment.update!(proposed_starts_at: nil, proposed_by_id: nil)

    Message.create!(
      appointment: @appointment,
      user: current_user,
      content: "Proposta RECUSADA (#{I18n.l(old, format: :short)})."
    )

    redirect_to appointment_path(@appointment), notice: "Proposta recusada."
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

  # Conflict helper for a proposed start against another accepted appointment
  def overlap_open_end?(candidate_start, other)
    cand_start = candidate_start
    cand_end   = candidate_start + 1.hour
    other_start = other.starts_at
    other_end   = other.ends_at || (other.starts_at + 1.hour)
    (cand_start < other_end) && (other_start < cand_end)
  end
end
