class Subscription < ApplicationRecord
  belongs_to :user

  monetize :price_cents, with_model_currency: :price_currency
end