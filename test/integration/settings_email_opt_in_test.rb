require "test_helper"

class SettingsEmailOptInTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "settings page shows the product updates toggle reflecting the flag" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select "h2", text: "Email me updates about SRO Labs"
    assert_select ".toggle input[type=checkbox]"
    assert_select ".toggle input[type=checkbox][checked]", count: 0

    @user.update!(email_opt_in: true)
    get settings_url
    assert_select ".toggle input[type=checkbox][checked]", count: 1
  end

  test "toggling persists the flag for the current user only" do
    other = create(:user)
    sign_in_as(@user)

    patch settings_email_opt_in_url, params: { email_opt_in: "1" }

    assert_redirected_to settings_url
    follow_redirect! while response.redirect?
    assert @user.reload.email_opt_in
    assert_not other.reload.email_opt_in

    patch settings_email_opt_in_url, params: { email_opt_in: "0" }
    assert_not @user.reload.email_opt_in
  end

  test "unauthenticated toggle is redirected to login" do
    patch settings_email_opt_in_url, params: { email_opt_in: "1" }

    assert_redirected_to new_session_url
  end
end
