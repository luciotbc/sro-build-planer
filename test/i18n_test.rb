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

  AUTH_HOME_VIEW_KEYS = %w[
    auth.email_placeholder
    auth.password_placeholder
    sessions.new.title
    sessions.form.email_label
    sessions.form.password_label
    sessions.form.remember_me
    sessions.form.submit
    sessions.form.forgot_password
    sessions.auth_modals.log_in
    sessions.auth_modals.create_account
    sessions.auth_modals.sign_in_title
    sessions.auth_modals.signup_title
    sessions.auth_modals.close
    sessions.auth_modals.new_here
    sessions.auth_modals.create_an_account
    sessions.auth_modals.already_have_account
    sessions.auth_modals.sign_in
    sessions.auth_modals.confirm_title
    sessions.auth_modals.confirmation_sent_html
    sessions.auth_modals.got_it
    sessions.auth_modals.resend
    registrations.new.title
    registrations.new.heading
    registrations.new.already_have_account
    registrations.new.sign_in
    registrations.form.email_label
    registrations.form.password_label
    registrations.form.password_hint
    registrations.form.password_confirmation_label
    registrations.form.terms_html
    registrations.form.terms_of_use
    registrations.form.privacy_policy
    registrations.form.email_opt_in
    registrations.form.email_opt_in_hint
    registrations.form.submit
    passwords.new.heading
    passwords.new.email_placeholder
    passwords.new.submit
    passwords.edit.heading
    passwords.edit.password_placeholder
    passwords.edit.password_confirmation_placeholder
    passwords.edit.submit
    home.hero.kicker
    home.hero.title_line1
    home.hero.title_line2
    home.hero.subtitle
    home.hero.cta
    home.hero.see_it_in_action
    home.features.kicker
    home.features.title
    home.features.subtitle
    home.features.full_trees_title
    home.features.full_trees_body
    home.features.sp_math_title
    home.features.sp_math_body
    home.features.multi_chars_title
    home.features.multi_chars_body
    home.cta_band.title
    home.cta_band.highlight
    home.cta_band.subtitle
    home.cta_band.cta
    home.live_preview.badge
    home.live_preview.title
    home.live_preview.subtitle
    home.live_preview.image_alt
  ].freeze

  it "defines every extracted key" do
    EXTRACTED_KEYS.each do |key|
      assert I18n.exists?(key), "missing i18n key: #{key}"
    end
  end

  it "defines every auth and home view key" do
    AUTH_HOME_VIEW_KEYS.each do |key|
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
