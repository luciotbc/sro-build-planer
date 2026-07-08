require "test_helper"

class SettingsMyDataTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "my data card lists email, dates and character count" do
    race = create(:race)
    create_list(:character, 2, user: @user, race: race)
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select "h2", text: "My data"
    assert_select "#settings-my-data" do
      assert_select ".data-row", count: 4
      assert_select ".data-row-value", text: @user.email_address
      assert_select ".data-row-value",
                    text: I18n.l(@user.created_at.to_date, format: :long),
                    count: 2
      assert_select ".data-row-value", text: "2"
    end
  end

  test "a user without characters sees zero" do
    sign_in_as(@user)

    get settings_url

    assert_select "#settings-my-data .data-row-value", text: "0"
  end
end
