class Settings::EmailOptInsController < ApplicationController
  def update
    Current.user.update!(
      email_opt_in: ActiveModel::Type::Boolean.new.cast(params[:email_opt_in])
    )

    redirect_to settings_path, notice: t("settings.email_opt_in.saved")
  end
end
