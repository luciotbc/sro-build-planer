require "test_helper"

class SettingsUpdatePasswordTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "settings page shows the update password card with the hidden rules panel" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select "h2", text: "Update password"
    assert_select "#settings_password_form input[name=?]", "current_password"
    assert_select "#settings_password_form input[name=?]", "password"
    assert_select "#settings_password_form input[name=?]",
                  "password_confirmation"
    assert_select "[data-controller~=?]", "password-rules"
    assert_select ".password-rules[hidden]"
    assert_select ".password-rules li[data-rule]", count: 4
  end

  test "valid change redirects with a success notice" do
    sign_in_as(@user)

    patch settings_password_url,
          params: {
            current_password: "Password1",
            password: "NewPassword2",
            password_confirmation: "NewPassword2"
          }

    assert_redirected_to settings_url
    follow_redirect! while response.redirect?
    assert @user.reload.authenticate("NewPassword2")
  end

  test "wrong current password renders the inline error via turbo stream" do
    sign_in_as(@user)

    patch settings_password_url,
          params: {
            current_password: "WrongPass9",
            password: "NewPassword2",
            password_confirmation: "NewPassword2"
          },
          as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match "settings_password_form", response.body
    assert @user.reload.authenticate("Password1")
  end

  test "unauthenticated update is redirected to login" do
    patch settings_password_url,
          params: {
            current_password: "Password1",
            password: "NewPassword2",
            password_confirmation: "NewPassword2"
          }

    assert_redirected_to new_session_url
  end
end
