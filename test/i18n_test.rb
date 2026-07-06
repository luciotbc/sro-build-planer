require "test_helper"

describe "i18n backend keys" do
  EXTRACTED_KEYS = %w[
    flash.rate_limited
    sessions.create.invalid_credentials
    passwords.create.instructions_sent
    passwords.update.reset
    passwords.update.mismatch
    passwords.invalid_token
    email_confirmations.show.confirmed
    email_confirmations.show.invalid_token
    email_confirmations.resend.sent
    characters.create.created
    characters.update.updated
    characters.destroy.deleted
    passwords_mailer.reset.subject
    users_mailer.email_confirmation.subject
    errors.skill_level.below_zero
    errors.skill_level.above_max
  ].freeze

  it "defines every extracted key" do
    EXTRACTED_KEYS.each do |key|
      assert I18n.exists?(key), "missing i18n key: #{key}"
    end
  end

  it "keeps mailer subjects stable" do
    assert_equal "Reset your password", I18n.t("passwords_mailer.reset.subject")
    assert_equal(
      "Confirm your email",
      I18n.t("users_mailer.email_confirmation.subject")
    )
  end

  it "interpolates skill level error messages" do
    assert_equal(
      "current_skill_level must be >= 0",
      I18n.t("errors.skill_level.below_zero", attr: "current_skill_level")
    )
    assert_equal(
      "target_skill_level must be <= 10",
      I18n.t(
        "errors.skill_level.above_max",
        attr: "target_skill_level",
        max: 10
      )
    )
  end
end
