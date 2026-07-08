require "test_helper"

class Users::UpdateEmailServiceTest < ActiveSupport::TestCase
  setup { @user = create(:user, :confirmed) }

  test "updates the email, resets confirmation and sends a new confirmation email" do
    result = nil
    assert_enqueued_email_with UsersMailer,
                               :email_confirmation,
                               args: [@user] do
      result =
        Users::UpdateEmailService.call(
          user: @user,
          email_address: "new@example.com"
        )
    end

    assert result.success?
    @user.reload
    assert_equal "new@example.com", @user.email_address
    assert_nil @user.email_confirmed_at
  end

  test "rejects an invalid email address and sends nothing" do
    result = nil
    assert_no_enqueued_emails do
      result =
        Users::UpdateEmailService.call(
          user: @user,
          email_address: "not-an-email"
        )
    end

    assert_not result.success?
    assert result.errors.any?
    assert @user.reload.email_confirmed_at.present?
  end

  test "rejects an email already taken without leaking account details" do
    other = create(:user)

    result = nil
    assert_no_enqueued_emails do
      result =
        Users::UpdateEmailService.call(
          user: @user,
          email_address: other.email_address
        )
    end

    assert_not result.success?
    assert result.errors.any?
    assert_no_match(/#{Regexp.escape(other.email_address)}/, result.errors.join)
  end

  test "unchanged email is a no-op with a warning and no mail" do
    result = nil
    assert_no_enqueued_emails do
      result =
        Users::UpdateEmailService.call(
          user: @user,
          email_address: @user.email_address
        )
    end

    assert result.success?
    assert result.warnings.any?
    assert @user.reload.email_confirmed_at.present?
  end
end
