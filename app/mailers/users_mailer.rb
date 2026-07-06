class UsersMailer < ApplicationMailer
  def email_confirmation(user)
    @user = user
    @confirmation_url =
      email_confirmation_url(
        token: user.generate_token_for(:email_confirmation)
      )
    mail to: user.email_address
  end
end
