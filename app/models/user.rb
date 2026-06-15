class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy, inverse_of: :user
  has_many :characters, dependent: :destroy, inverse_of: :user

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address,
            presence: true,
            uniqueness: {
              case_sensitive: false
            }
end
