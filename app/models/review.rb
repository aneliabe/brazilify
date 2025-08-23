class Review < ApplicationRecord
  belongs_to :user
  belongs_to :worker_profile

  validates :rating, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 1000 }
end
