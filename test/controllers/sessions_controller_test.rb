require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = create(:user, password: "password") }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path,
         params: {
           email_address: @user.email_address,
           password: "password"
         }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path,
         params: {
           email_address: @user.email_address,
           password: "wrong"
         }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(@user)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end

  test "logout clears character_id so next user does not inherit it" do
    race = create(:race)
    user_a = create(:user, password: "pass")
    char_a = create(:character, user: user_a, race: race)

    user_b = create(:user, password: "pass")

    # Sign in as user A and select their character
    post session_path,
         params: {
           email_address: user_a.email_address,
           password: "pass"
         }
    post select_character_path(char_a)

    # Logout via the real destroy action (clears session)
    delete session_path
    assert_redirected_to new_session_path

    # Sign in as user B (no characters)
    post session_path,
         params: {
           email_address: user_b.email_address,
           password: "pass"
         }
    assert_redirected_to root_path

    # Home page must not show user A's character
    get root_path
    assert_response :success
    assert_no_match char_a.name, response.body
  end
end
