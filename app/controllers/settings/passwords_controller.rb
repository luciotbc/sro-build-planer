class Settings::PasswordsController < ApplicationController
  rate_limit to: 10,
             within: 3.minutes,
             only: :update,
             with: -> do
               redirect_to settings_path, alert: t("flash.rate_limited")
             end

  def update
    result =
      Users::UpdatePasswordService.call(
        user: Current.user,
        current_password: params[:current_password],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        current_session: Current.session
      )

    if result.success?
      redirect_to settings_path, notice: t("settings.password.updated")
    else
      render_form(result.errors)
    end
  end

  private

  def render_form(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream:
                 turbo_stream.replace(
                   "settings_password_form",
                   partial: "settings/password_form",
                   locals: {
                     errors: errors
                   }
                 ),
               status: :unprocessable_entity
      end
      format.html { redirect_to settings_path, alert: errors.to_sentence }
    end
  end
end
