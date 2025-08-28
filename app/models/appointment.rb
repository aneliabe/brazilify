class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :worker_profile

  has_many :messages, dependent: :destroy

  STATUSES = %w[pending accepted declined].freeze

  validates :starts_at, presence: true
  # ✅ keep status sane (allow nil temporarily so old rows don’t break)
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  before_validation :set_default_status, on: :create

  def participants
    [user, worker_profile.user]
  end

  def participant?(someone)
    participants.include?(someone)
  end

  private

  def set_default_status
    self.status ||= "pending"
  end
end
