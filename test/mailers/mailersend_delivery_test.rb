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

  it "base64-encodes file attachments onto the MailerSend email" do
    mail =
      Mail.new do
        from "app@example.com"
        to "user@example.com"
        subject "Report"
        body "see attached"
        add_file(filename: "report.txt", content: "hello world")
      end

    email = MailersendDelivery.new.build_email(mail, client)

    assert_equal 1, email.attachments.size
    attachment = email.attachments.first
    assert_equal "report.txt", attachment["filename"]
    assert_equal "attachment", attachment["disposition"]
    assert_equal "hello world", Base64.decode64(attachment["content"])
    # The body still maps correctly alongside the attachment.
    assert_equal "see attached", email.text
  end

  it "marks inline attachments and carries their content id for cid: refs" do
    mail =
      Mail.new do
        from "app@example.com"
        to "user@example.com"
        subject "Inline"
        html_part do
          content_type "text/html; charset=UTF-8"
          body '<img src="cid:logo.png">'
        end
      end
    mail.attachments.inline["logo.png"] = "PNGDATA"

    email = MailersendDelivery.new.build_email(mail, client)

    attachment = email.attachments.first
    assert_equal "inline", attachment["disposition"]
    assert_equal mail.attachments.first.cid, attachment["id"]
    assert_equal "PNGDATA", Base64.decode64(attachment["content"])
  end

  it "sends no attachments key when the message has none" do
    mail =
      Mail.new do
        from "app@example.com"
        to "user@example.com"
        subject "Plain"
        body "hi"
      end

    email = MailersendDelivery.new.build_email(mail, client)

    assert_empty email.attachments
  end

  it "raises when the api_token credential is missing" do
    # test env carries no :mailersend credentials, so the token is nil.
    assert_nil Rails.application.credentials.dig(:mailersend, :api_token)
    mail = Mail.new { body "x" }
    assert_raises(ArgumentError) { MailersendDelivery.new.deliver!(mail) }
  end
end
