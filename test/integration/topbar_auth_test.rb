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

  test "authenticated user is redirected from home to characters index" do
    sign_in_as(@user)

    get root_url

    assert_redirected_to characters_path
  end

  test "authenticated topbar shows the logout button" do
    sign_in_as(@user)

    get characters_url

    assert_response :success
    assert_select "button", text: "Log out"
    assert_select "button", text: "Log in", count: 0
  end
end
