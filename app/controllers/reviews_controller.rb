class ReviewsController < ApplicationController
  before_action :authenticate_user!

  def create
    wp = WorkerProfile.find(params[:worker_profile_id])

    # must have at least one accepted, past appointment with this pro
    allowed = Appointment
      .where(user_id: current_user.id, worker_profile_id: wp.id, status: "accepted")
      .where("starts_at < ?", Time.zone.now)
      .exists?

    unless allowed
      return redirect_to worker_path(wp), alert: "Você só pode avaliar após um atendimento concluído."
    end

    # prevent duplicate review from same user to same pro (simple rule)
    if Review.exists?(user_id: current_user.id, worker_profile_id: wp.id)
      return redirect_to worker_path(wp), alert: "Você já avaliou este profissional."
    end

    review = Review.new(
      worker_profile: wp,
      user: current_user,
      rating: params[:rating].to_i,
      comment: params[:comment].to_s.strip
    )

    if review.save
      redirect_to worker_path(wp), notice: "Avaliação enviada. Obrigado!"
    else
      redirect_to worker_path(wp), alert: review.errors.full_messages.to_sentence
    end
  end
end
