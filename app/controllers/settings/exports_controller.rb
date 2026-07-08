class Settings::ExportsController < ApplicationController
  rate_limit to: 2,
             within: 10.minutes,
             only: :create,
             with: -> do
               redirect_to settings_path, alert: t("flash.rate_limited")
             end

  def create
    Users::ExportDataJob.perform_later(Current.user)

    redirect_to settings_path, notice: t("settings.my_data.export_enqueued")
  end
end
