class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    wp   = WorkerProfile.find(params[:worker_profile_id])
    appt = Appointment.find(params[:appointment_id]) if params[:appointment_id].present?

    # can only review if you are the client & the appointment time already passed
    past         = appt&.starts_at.present? && appt.starts_at < Time.zone.now
    valid_status = %w[accepted pending].include?(appt&.status.to_s)
    unless appt && appt.user_id == current_user.id && appt.worker_profile_id == wp.id && past && valid_status
      return redirect_back fallback_location: worker_path(wp), alert: "Você só pode avaliar após o horário do atendimento."
    end

    # one review per user–pro (current rule) — we edit the latest if it exists
    my_review = Review.where(worker_profile_id: wp.id, user_id: current_user.id).order(created_at: :desc).first
    if my_review
      # if user somehow hits "create" again, treat as update
      return update_existing(my_review, rating: params[:rating], comment: params[:comment], return_to: appointment_path(appt))
    end

    review = Review.new(
      worker_profile: wp,
      user:           current_user,
      rating:         params[:rating].to_i,
      comment:        params[:comment].to_s.strip
    )

    if review.save
      redirect_to appointment_path(appt), notice: "Avaliação enviada. Obrigado!"
    else
      redirect_to appointment_path(appt), alert: review.errors.full_messages.to_sentence
    end
  end

  def update
    review = Review.find(params[:id])
    return redirect_back fallback_location: root_path, alert: "Sem permissão." unless review.user_id == current_user.id

    update_existing(review, rating: params[:rating], comment: params[:comment], return_to: params[:return_to])
  end

  def destroy
    review = Review.find(params[:id])
    return redirect_back fallback_location: root_path, alert: "Sem permissão." unless review.user_id == current_user.id

    review.destroy!
    redirect_to (params[:return_to].presence || worker_path(review.worker_profile)), notice: "Avaliação removida."
  end

  private

  def update_existing(review, rating:, comment:, return_to:)
    if review.update(rating: rating.to_i, comment: comment.to_s.strip)
      redirect_to (return_to.presence || worker_path(review.worker_profile)), notice: "Avaliação atualizada."
    else
      redirect_to (return_to.presence || worker_path(review.worker_profile)), alert: review.errors.full_messages.to_sentence
    end
  end
end
