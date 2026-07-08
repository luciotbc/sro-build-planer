class Settings::EmailsController < ApplicationController
  rate_limit to: 10,
             within: 3.minutes,
             only: :update,
             with: -> do
               redirect_to settings_path, alert: t("flash.rate_limited")
             end

  def update
    result =
      Users::UpdateEmailService.call(
        user: Current.user,
        email_address: params[:email_address]
      )

    if result.success?
      notice = result.warnings.first || t("settings.email.updated_check_inbox")
      redirect_to settings_path, notice: notice
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
                   "settings_email_form",
                   partial: "settings/email_form",
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
