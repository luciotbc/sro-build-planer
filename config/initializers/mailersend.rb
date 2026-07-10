# frozen_string_literal: true

require "mailersend-ruby"

# Action Mailer delivery method that sends through MailerSend's HTTP API.
#
# Railway (our production host) blocks all outbound SMTP, so the SMTP transport
# cannot reach MailerSend. This adapter forwards the Mail::Message that Action
# Mailer builds to the MailerSend v1 /email endpoint over HTTPS instead, which
# keeps every existing mailer, view, locale wrapper and deliver_later intact.
#
# The API token is read from encrypted credentials (mailersend.api_token).
class MailersendDelivery
  def initialize(settings = {})
    @settings = settings
  end

  def deliver!(mail)
    token = Rails.application.credentials.dig(:mailersend, :api_token)
    if token.blank?
      raise ArgumentError, "Missing mailersend.api_token credential"
    end

    response = build_email(mail, Mailersend::Client.new(token)).send
    unless response.status.success?
      raise "MailerSend API error: HTTP #{response.code} #{response.body}"
    end

    response
  end

  # Translates the Mail::Message Action Mailer built into a configured
  # Mailersend::Email (public so it can be unit-tested without the network).
  def build_email(mail, client)
    email = Mailersend::Email.new(client)
    email.add_from("email" => first_address(mail.from))
    Array(mail.to).each { |to| email.add_recipients("email" => to) }
    Array(mail.cc).each { |cc| email.add_cc("email" => cc) }
    Array(mail.bcc).each { |bcc| email.add_bcc("email" => bcc) }
    if (reply_to = first_address(mail.reply_to))
      email.add_reply_to("email" => reply_to)
    end
    email.add_subject(mail.subject.to_s)

    html = part_body(mail, "text/html")
    text = part_body(mail, "text/plain")
    email.add_html(html) if html.present?
    email.add_text(text.presence || strip_tags(html))
    add_attachments(email, mail)
    email
  end

  private

  def first_address(field)
    Array(field).first
  end

  # Action Mailer carries attachments as separate MIME parts; MailerSend expects
  # them base64-encoded inside the JSON payload.
  def add_attachments(email, mail)
    mail.attachments.each do |attachment|
      inline = attachment.inline?
      email.add_attachment(
        content: Base64.strict_encode64(attachment.body.decoded),
        filename: attachment.filename,
        disposition: inline ? "inline" : "attachment"
      )

      # Inline parts need an `id` so `cid:` references in the HTML body resolve.
      # The gem's add_attachment does not expose it, so set it on the payload.
      if inline && attachment.cid.present?
        email.attachments.last["id"] = attachment.cid
      end
    end
  end

  def part_body(mail, mime_type)
    if mail.multipart?
      part = mime_type == "text/html" ? mail.html_part : mail.text_part
      part&.body&.decoded
    elsif mail.mime_type == mime_type ||
          (mime_type == "text/plain" && mail.mime_type.blank?)
      # A single-part message with no explicit Content-Type is plain text.
      mail.body.decoded
    end
  end

  def strip_tags(html)
    return "" if html.blank?

    ActionController::Base.helpers.strip_tags(html).squish
  end
end

ActionMailer::Base.add_delivery_method :mailersend, MailersendDelivery
