class WorkerProfile < ApplicationRecord
  belongs_to :user
  has_many :worker_services, dependent: :destroy
  has_many :services, through: :worker_services
  has_many :reviews, dependent: :destroy
  has_many :appointments, dependent: :destroy

  accepts_nested_attributes_for :worker_services, allow_destroy: true, reject_if: :all_blank

  validates :cpf, presence: true, uniqueness: true
  validates :description, presence: true

  def average_rating
    reviews.average(:rating)&.round(2) || 0
  end
end
