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

  test "authenticated topbar shows the logout button" do
    sign_in_as(@user)

    get root_url
    follow_redirect! while response.redirect?

    assert_response :success
    assert_select "button", text: "Log out"
    assert_select "button", text: "Log in", count: 0
  end
end
