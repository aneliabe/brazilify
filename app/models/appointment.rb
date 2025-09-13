class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :worker_profile
  belongs_to :proposed_by, class_name: "User", optional: true

  has_many :messages, dependent: :destroy

  STATUSES = %w[pending accepted declined].freeze

  # 🔹 time zone must be present (IANA id, e.g. "America/Sao_Paulo")
  validates :time_zone, presence: true

  # existing validations
  validate  :proposed_by_must_be_participant, if: -> { proposed_by_id.present? }
  validates :starts_at, presence: true
  validate  :client_cannot_equal_worker
  validate  :starts_at_not_in_past, on: :create
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  before_validation :set_default_status, on: :create

  # Participants
  def participants
    [user, worker_profile.user]
  end

  def participant?(someone)
    participants.include?(someone)
  end

  # Who proposed?
  def proposed_by_role
    return :client if proposed_by_id == user_id
    return :worker if worker_profile && proposed_by_id == worker_profile.user_id
    nil
  end

  # 🔹 The appointment's ActiveSupport::TimeZone helper
  def zone
    ActiveSupport::TimeZone[time_zone] || Time.zone
  end

  # 🔹 "not in past" evaluated in the appointment's own zone
  def starts_at_not_in_past
    return if starts_at.blank?
    Time.use_zone(zone) do
      errors.add(:starts_at, "não pode ser no passado") if starts_at < Time.zone.now
    end
  end

  # --- archive helpers (public) ---
  def archived_by_client?
    archived_by_client_at.present?
  end

  def archived_by_worker?
    archived_by_worker_at.present?
  end

  # Freeze chat for BOTH sides if EITHER side archived
  def frozen_chat?
    archived_by_client? || archived_by_worker?
  end

  # (optional) keep this public so views can call it
  # Only allow archive if appointment is in the past AND this user has reviewed
  def can_archive?(who)
    return false unless starts_at.present? && starts_at < Time.zone.now
    Review.exists?(appointment_id: id, user_id: who.id)
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def proposed_by_must_be_participant
    unless [user_id, worker_profile&.user_id].include?(proposed_by_id)
      errors.add(:proposed_by_id, "must be the client or the worker of this appointment")
    end
  end

  def client_cannot_equal_worker
    if worker_profile&.user_id == user_id
      errors.add(:base, "Você não pode agendar consigo mesmo.")
    end
  end
end
