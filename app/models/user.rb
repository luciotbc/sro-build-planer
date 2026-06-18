class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :email_confirmation, expires_in: 1.day

  validates :email_address,
            presence: true,
            uniqueness: true,
            format: {
              with: URI::MailTo::EMAIL_REGEXP
            }
  validates :password,
            length: {
              minimum: 8
            },
            format: {
              with: /\A(?=.*[A-Z])(?=.*\d).+\z/,
              message: "must include an uppercase letter and a number"
            },
            allow_nil: true

  def email_confirmed? = email_confirmed_at.present?

  def confirm_email! = update!(email_confirmed_at: Time.current)
end
