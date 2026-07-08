class Settings::AccountsController < ApplicationController
  def destroy
    result =
      Users::DeleteAccountService.call(
        user: Current.user,
        confirmation: params[:confirmation]
      )

    if result.success?
      terminate_session
      redirect_to root_path, notice: t("settings.delete_account.deleted")
    else
      redirect_to settings_path, alert: result.errors.to_sentence
    end
  end
end
