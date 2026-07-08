require "test_helper"

class SettingsUpdateEmailTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "settings page shows the update email card prefilled with the current email" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select "h2", text: "Update email"
    assert_select "#settings_email_form input[name=?][value=?]",
                  "email_address",
                  @user.email_address
  end

  test "valid email change redirects with a verification notice" do
    sign_in_as(@user)

    patch settings_email_url, params: { email_address: "new@example.com" }

    assert_redirected_to settings_url
    follow_redirect! while response.redirect?
    assert_equal "new@example.com", @user.reload.email_address
    assert_nil @user.email_confirmed_at
  end

  test "invalid email renders the inline error via turbo stream" do
    sign_in_as(@user)

    patch settings_email_url,
          params: {
            email_address: "nope"
          },
          as: :turbo_stream

    assert_response :unprocessable_entity
    assert_match "settings_email_form", response.body
    assert_equal @user.email_address, @user.reload.email_address
  end

  test "unauthenticated update is redirected to login" do
    patch settings_email_url, params: { email_address: "new@example.com" }

    assert_redirected_to new_session_url
  end
end
