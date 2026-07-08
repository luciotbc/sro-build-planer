require "test_helper"

class TopbarAuthTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "unauthenticated topbar shows the login trigger and modal form" do
    get root_url

    assert_response :success
    assert_select "button", text: "Log in"
    assert_select "dialog.modal input[name=?]", "email_address"
    assert_select "button", text: "Log out", count: 0
  end

  test "unauthenticated topbar shows a primary Create account trigger" do
    get root_url

    assert_response :success
    assert_select "button[data-action*='auth#showSignup']",
                  text: "Create account"
  end

  test "login and signup modals are not dismissable via backdrop click" do
    get root_url

    assert_response :success
    assert_select "dialog[data-auth-target='login']"
    assert_select "dialog[data-auth-target='signup']"
    assert_select "dialog[data-auth-target='login'][data-action*='backdropClose']",
                  count: 0
    assert_select "dialog[data-auth-target='signup'][data-action*='backdropClose']",
                  count: 0
    assert_select "dialog[data-auth-target='login'] button[data-action='auth#close']"
    assert_select "dialog[data-auth-target='signup'] button[data-action='auth#close']"
  end

  test "authenticated topbar shows the user-settings menu, not a bare logout button" do
    sign_in_as(@user)

    get root_url
    follow_redirect! while response.redirect?

    assert_response :success
    # Avatar trigger for the dropdown menu.
    assert_select ".user-menu [data-menu-target='trigger'][aria-haspopup='menu']"
    assert_select "button", text: "Log in", count: 0
  end

  test "user menu links to account settings and logs out via DELETE" do
    sign_in_as(@user)

    get root_url
    follow_redirect! while response.redirect?

    assert_response :success
    # Account settings entry navigates to /settings.
    assert_select ".menu-panel a.menu-item[href=?]",
                  settings_path,
                  text: "Account settings"
    # Log out stays a DELETE form-button (CSRF-safe, non-GET).
    assert_select ".menu-panel form[action=?][method=post]", session_path do
      assert_select "input[name='_method'][value='delete']", count: 1
      assert_select "button", text: "Log out"
    end
  end

  test "user menu does not include a language item" do
    sign_in_as(@user)

    get root_url
    follow_redirect! while response.redirect?

    assert_response :success
    # Exactly two entries — Account settings + Log out — and no language item.
    assert_select ".menu-panel .menu-item", count: 2
    assert_select ".menu-panel a.menu-item", count: 1, text: "Account settings"
  end
end
