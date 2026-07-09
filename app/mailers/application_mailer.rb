class ApplicationMailer < ActionMailer::Base
  default from:
            Rails.application.credentials.dig(:smtp, :from) ||
              "from@example.com"
  layout "mailer"

  # Render the subject + body in the recipient's saved locale (docs/todo/033).
  # Wrapping `mail` covers deliver_later too — the delivery job does not carry
  # the request locale, so it must be resolved from the User at render time.
  # Every mailer sets @user before calling `mail`.
  def mail(headers = {}, &block)
    I18n.with_locale(@user&.locale.presence || I18n.default_locale) { super }
  end
end
