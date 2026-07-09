require "test_helper"

class ApplicationMailerTest < ActiveSupport::TestCase
  it "falls back to the placeholder sender when no mailersend:from credential is set" do
    # test/dev carry no :mailersend credentials; production overrides via
    # credentials.dig(:mailersend, :from). Guards the fallback in ApplicationMailer.
    assert_nil Rails.application.credentials.dig(:mailersend, :from)
    assert_equal "from@example.com", ApplicationMailer.default[:from]
  end
end
