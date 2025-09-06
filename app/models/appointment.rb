class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :worker_profile
  belongs_to :proposed_by, class_name: "User", optional: true

  has_many :messages, dependent: :destroy

  STATUSES = %w[pending accepted declined].freeze

  validate :proposed_by_must_be_participant, if: -> { proposed_by_id.present? }
  validates :starts_at, presence: true
  validate :client_cannot_equal_worker
  # ✅ keep status sane (allow nil temporarily so old rows don’t break)
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  before_validation :set_default_status, on: :create

  def participants
    [user, worker_profile.user]
  end

  def participant?(someone)
    participants.include?(someone)
  end

  def proposed_by_role
    return :client if proposed_by_id == user_id
    return :worker if worker_profile && proposed_by_id == worker_profile.user_id
    nil
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
