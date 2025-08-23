class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { client: 0, worker: 1, admin: 2 }

  has_one :worker_profile, dependent: :destroy
  has_many :reviews, dependent: :nullify
end
