require "test_helper"

class PasswordRecoveryRulesTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "reset page renders the shared password fields with the hidden rules panel" do
    token = @user.password_reset_token

    get edit_password_url(token)

    assert_response :success
    assert_select "[data-controller~=?]", "password-rules"
    assert_select "input[name=?]", "password"
    assert_select "input[name=?]", "password_confirmation"
    assert_select ".password-rules[hidden]"
    assert_select ".password-rules li[data-rule]", count: 4
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
