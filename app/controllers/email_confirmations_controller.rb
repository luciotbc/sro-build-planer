class EmailConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    if user = User.find_by_token_for(:email_confirmation, params[:token])
      user.confirm_email! unless user.email_confirmed?
      start_new_session_for user
      redirect_to root_path, notice: "Email confirmed. Welcome to SRO Labs!"
    else
      redirect_to root_path,
                  alert: "That confirmation link is invalid or has expired."
    end
  end

  def resend
    user = User.find_by(email_address: params[:email_address])
    if user&.email_confirmed? == false
      UsersMailer.email_confirmation(user).deliver_later
    end

    redirect_to root_path,
                flash: {
                  registered_email: params[:email_address],
                  notice:
                    "If your account still needs confirmation, we've sent a new link."
                }
  end
end
