class Settings::LocalesController < ApplicationController
  def update
    result =
      Users::UpdateLocaleService.call(
        user: Current.user,
        locale: params[:locale]
      )

    if result.success?
      redirect_back fallback_location: root_path, notice: t(".updated")
    else
      redirect_back fallback_location: root_path,
                    alert: result.errors.to_sentence
    end
  end
end
