require "test_helper"

class SettingsLanguageTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, :confirmed) }

  test "the user menu renders a Language item with the active flag and all options" do
    sign_in_as(@user)

    get settings_url

    assert_response :success
    assert_select ".menu-submenu-trigger" do
      assert_select ".menu-flag", text: "🇺🇸"
    end
    assert_select ".submenu-panel .menu-locale", count: LocaleOption.all.size
    assert_select ".menu-locale-code", text: "pt-BR"
  end

  test "selecting a supported locale persists it and redirects back" do
    sign_in_as(@user)

    patch settings_locale_url,
          params: {
            locale: "pt-BR"
          },
          headers: {
            "Referer" => settings_url
          }

    assert_redirected_to settings_url
    assert_equal "pt-BR", @user.reload.locale
  end

  test "an unsupported locale is rejected and leaves the selection unchanged" do
    @user.update!(locale: "es")
    sign_in_as(@user)

    patch settings_locale_url, params: { locale: "xx" }

    assert_equal "es", @user.reload.locale
  end

  test "requires authentication" do
    patch settings_locale_url, params: { locale: "pt-BR" }

    assert_redirected_to new_session_url
  end
end
