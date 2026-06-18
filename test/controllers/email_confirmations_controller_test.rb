require "test_helper"

class EmailConfirmationsControllerTest < ActionDispatch::IntegrationTest
  it "confirms the account, signs the user in and redirects home" do
    user = create(:user)
    token = user.generate_token_for(:email_confirmation)

    get email_confirmation_path(token: token)

    assert_redirected_to root_path
    assert user.reload.email_confirmed?
    assert cookies[:session_id].present?
  end

  it "rejects an invalid token without signing in" do
    get email_confirmation_path(token: "garbage")

    assert_redirected_to root_path
    assert cookies[:session_id].blank?
    follow_redirect!
    assert_match(/invalid or has expired/i, response.body)
  end

  it "resends a confirmation email to an unconfirmed user" do
    user = create(:user)

    assert_enqueued_emails 1 do
      post resend_email_confirmation_path,
           params: {
             email_address: user.email_address
           }
    end
    assert_redirected_to root_path
  end

  it "does not resend to a confirmed user but still redirects neutrally" do
    user = create(:user, :confirmed)

    assert_no_enqueued_emails do
      post resend_email_confirmation_path,
           params: {
             email_address: user.email_address
           }
    end
    assert_redirected_to root_path
  end

  it "does not reveal whether an unknown email exists" do
    assert_no_enqueued_emails do
      post resend_email_confirmation_path,
           params: {
             email_address: "ghost@example.com"
           }
    end
    assert_redirected_to root_path
  end
end
