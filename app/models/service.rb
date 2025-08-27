class Service < ApplicationRecord
  belongs_to :category
  has_many :worker_services, dependent: :destroy
  has_many :worker_profiles, through: :worker_services

  enum service_type: { remote: "remoto", on_site: "presencial", establishment: "estabelecimento" }

  validates :service_type, presence: true, inclusion: { in: service_types.keys }
end
