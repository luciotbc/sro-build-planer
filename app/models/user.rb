class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :characters, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Embeds email_confirmed_at so a link stops resolving once the account is
  # confirmed: the token is single-use rather than a 24h reusable login link.
  generates_token_for :email_confirmation, expires_in: 1.day do
    email_confirmed_at
  end

  validates :email_address,
            presence: true,
            uniqueness: true,
            format: {
              with: URI::MailTo::EMAIL_REGEXP
            }
  validates :locale,
            inclusion: {
              in: I18n.available_locales.map(&:to_s)
            },
            allow_nil: true
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
