require "test_helper"

class SettingsDeleteAccountTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "settings page shows the danger card and confirmation modal" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select ".settings-card--danger h2", text: "Delete account"
    assert_select "dialog#delete-account-modal" do
      assert_select "input[name=?]", "confirmation"
      assert_select "button[type=submit][disabled]"
    end
  end

  test "delete without the typed confirmation fails and keeps the account" do
    sign_in_as(@user)

    delete settings_account_url, params: { confirmation: "delete me" }

    assert_redirected_to settings_url
    assert User.exists?(@user.id)
  end

  test "confirmed delete destroys the account, signs out and redirects home" do
    sign_in_as(@user)

    delete settings_account_url, params: { confirmation: "DELETE" }

    assert_redirected_to root_url
    assert_not User.exists?(@user.id)

    get settings_url
    assert_redirected_to new_session_url
  end

  test "unauthenticated delete is redirected to login" do
    delete settings_account_url, params: { confirmation: "DELETE" }

    assert_redirected_to new_session_url
    assert User.exists?(@user.id)
  end
end
