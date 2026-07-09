require "test_helper"

class ApplicationMailerTest < ActiveSupport::TestCase
  it "falls back to the placeholder sender when no smtp:from credential is set" do
    # test/dev carry no :smtp credentials; production overrides via
    # credentials.dig(:smtp, :from). Guards the fallback in ApplicationMailer.
    assert_nil Rails.application.credentials.dig(:smtp, :from)
    assert_equal "from@example.com", ApplicationMailer.default[:from]
  end
end
