class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable #, :validatable, :confirmable

  enum role: { client: 0, worker: 1, admin: 2 }

  has_one :subscription, dependent: :destroy
  has_one :worker_profile, dependent: :destroy
  has_many :reviews, dependent: :nullify
  has_many :appointments, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_one_attached :photo


  after_initialize :set_default_role, if: :new_record?

  def setup_stripe_customer
    return if stripe_customer_id.present?
    customer = Stripe::Customer.create(email: email)
    update(stripe_customer_id: customer.id)
  end

  private

  def set_default_role
    self.role ||= :client
  end
end
