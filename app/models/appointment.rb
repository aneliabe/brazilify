class Appointment < ApplicationRecord
  belongs_to :user
  belongs_to :worker_profile

  has_many :messages, dependent: :destroy

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts

  def participants
    [user, worker_profile.user]
  end

  def participant?(someone)
    participants.include?(someone)
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    errors.add(:ends_at, "must be after start") if ends_at <= starts_at
  end
end
