class AppointmentRequest < ApplicationRecord
  belongs_to :worker_profile
  belongs_to :user  # requester (current_user)

  STATUSES = %w[pending accepted declined].freeze

  validates :preferred_datetime, presence: true
  validates :status, inclusion: { in: STATUSES }
  before_validation :set_default_status, on: :create

  private
  
  def set_default_status
    self.status ||= "pending"
  end
end
