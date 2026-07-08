module Users
  class ExportDataJob < ApplicationJob
    queue_as :default

    def perform(user)
      result = Users::ExportDataService.call(user: user)
      UsersMailer.data_export(
        user,
        filename: result.data[:filename],
        content: result.data[:content]
      ).deliver_now
    end
  end
end
