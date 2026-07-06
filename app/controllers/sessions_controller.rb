class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10,
             within: 3.minutes,
             only: :create,
             with: -> do
               redirect_to new_session_path, alert: t("flash.rate_limited")
             end

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user, remember: params[:remember_me] == "1"
      redirect_to after_authentication_url
    else
      alert = t(".invalid_credentials")
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream:
                   turbo_stream.replace(
                     "login_form",
                     partial: "sessions/form",
                     locals: {
                       alert: alert
                     }
                   ),
                 status: :unprocessable_entity
        end
        format.html { redirect_to new_session_path, alert: alert }
      end
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, status: :see_other
  end
end
