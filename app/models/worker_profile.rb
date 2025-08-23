class WorkerProfile < ApplicationRecord
  belongs_to :user
  has_many :worker_services, dependent: :destroy
  has_many :services, through: :worker_services
end
