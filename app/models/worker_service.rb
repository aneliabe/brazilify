class WorkerService < ApplicationRecord
  belongs_to :worker_profile
  belongs_to :service
  belongs_to :category

  enum service_type: { remote: "remoto", on_site: "presencial", establishment: "estabelecimento" }

  validates :service_type, presence: true
  validates :category, presence: true
  validates :service, presence: true
end
