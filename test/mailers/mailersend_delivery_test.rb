require "test_helper"

class MailersendDeliveryTest < ActiveSupport::TestCase
  # Mailersend::Client just stores the token — no network on construction.
  def client = Mailersend::Client.new("test-token")

  it "maps sender, recipient, subject and text body onto the MailerSend email" do
    mail =
      Mail.new do
        from "app@example.com"
        to "user@example.com"
        subject "Welcome"
        body "hello"
      end

    email = MailersendDelivery.new.build_email(mail, client)

    assert_equal({ "email" => "app@example.com" }, email.from)
    assert_equal [{ "email" => "user@example.com" }], email.recipients
    assert_equal "Welcome", email.subject
    assert_equal "hello", email.text
  end

  it "splits a multipart message into html and text parts" do
    mail =
      Mail.new do
        from "app@example.com"
        to "user@example.com"
        subject "Multi"
        text_part { body "plain body" }
        html_part { body "<p>rich body</p>" }
      end

    email = MailersendDelivery.new.build_email(mail, client)

    assert_equal "<p>rich body</p>", email.html
    assert_equal "plain body", email.text
  end

  it "carries cc and reply-to through to the MailerSend email" do
    mail =
      Mail.new do
        from "app@example.com"
        to "user@example.com"
        cc "watcher@example.com"
        reply_to "support@example.com"
        subject "Hi"
        body "hello"
      end

    email = MailersendDelivery.new.build_email(mail, client)

    assert_equal [{ "email" => "watcher@example.com" }], email.ccs
    assert_equal({ "email" => "support@example.com" }, email.reply_to)
  end

  it "raises when the api_token credential is missing" do
    # test env carries no :mailersend credentials, so the token is nil.
    assert_nil Rails.application.credentials.dig(:mailersend, :api_token)
    mail = Mail.new { body "x" }
    assert_raises(ArgumentError) { MailersendDelivery.new.deliver!(mail) }
  end
end
