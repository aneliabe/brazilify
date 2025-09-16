class Review < ApplicationRecord
  belongs_to :user
  belongs_to :worker_profile
  belongs_to :appointment, optional: true   # <= add this

  validates :rating, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 1000 }
end
