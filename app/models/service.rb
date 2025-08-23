class Service < ApplicationRecord
  belongs_to :category
  has_many :worker_services, dependent: :destroy
  has_many :worker_profiles, through: :worker_services
end
