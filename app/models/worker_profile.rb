class WorkerProfile < ApplicationRecord
  belongs_to :user
  has_many :worker_services, dependent: :destroy
  has_many :services, through: :worker_services
  has_many :reviews, dependent: :destroy

  def average_rating
    reviews.average(:rating)&.round(2) || 0
  end
end
