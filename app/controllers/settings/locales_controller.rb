class Settings::LocalesController < ApplicationController
  # Guests switch the UI language too (from the footer); the choice lives in the
  # session and is persisted to users.locale once signed in (spec 08 R12).
  allow_unauthenticated_access only: :update

  def update
    result =
      Users::UpdateLocaleService.call(
        user: Current.user,
        locale: params[:locale]
      )

    if result.success?
      session[:locale] = result.data
      redirect_back fallback_location: root_path, notice: t(".updated")
    else
      redirect_back fallback_location: root_path,
                    alert: result.errors.to_sentence
    end
  end
end
