require "test_helper"

class SettingsPageTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "authenticated user sees the account settings page shell" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select "h1", text: "Account settings"
    assert_select "p",
                  text:
                    "Manage your login credentials, notifications, and account data."
    assert_select "#settings-sections"
  end

  test "unauthenticated visitor is redirected to login" do
    get settings_url

    assert_redirected_to new_session_url
  end
end
