require "test_helper"

class Users::ExportDataJobTest < ActiveJob::TestCase
  test "emails the user a zip attachment" do
    user = create(:user, :confirmed)

    assert_emails 1 do
      Users::ExportDataJob.perform_now(user)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [user.email_address], mail.to
    assert_equal 1, mail.attachments.size
    assert_match(/\Asrolabs_\d{14}\.zip\z/, mail.attachments.first.filename)
  end
end
