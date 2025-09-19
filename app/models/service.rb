class Service < ApplicationRecord
  belongs_to :category
  has_many :worker_services, dependent: :destroy
  has_many :worker_profiles, through: :worker_services

  POPULAR_SERVICE_NAMES = [
    'Diarista',
    'Cabeleireiro',
    'Manicure',
    'Encanador',
    'Eletricista',
    'Motorista Particular',
    'Frete/Carretos',
    'Babá',
    'Pintura'
  ].freeze

  def self.popular_services
    found = where(name: POPULAR_SERVICE_NAMES).distinct.to_a

    POPULAR_SERVICE_NAMES.map { |name|
      found.find { |service| service.name == name }
    }.compact
  end
end
