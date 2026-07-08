require "test_helper"

class PasswordRecoveryRulesTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "reset page renders the shared password fields with the hidden rules panel" do
    token = @user.password_reset_token

    get edit_password_url(token)

    assert_response :success
    # Scope to the reset form: the unauthenticated page also renders the
    # topbar signup modal, which carries its own password-rules panel.
    assert_select "#password_reset_form[data-controller~=?]", "password-rules"
    assert_select "#password_reset_form input[name=?]", "password"
    assert_select "#password_reset_form input[name=?]", "password_confirmation"
    assert_select "#password_reset_form .password-rules[hidden]"
    assert_select "#password_reset_form .password-rules li[data-rule]", count: 4
  end

  test "reset flow still updates the password" do
    token = @user.password_reset_token

    put password_url(token),
        params: {
          password: "NewPassword2",
          password_confirmation: "NewPassword2"
        }

    assert_redirected_to new_session_url
    assert @user.reload.authenticate("NewPassword2")
  end
end
