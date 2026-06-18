require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

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

  test "create with invalid credentials via turbo stream renders error inline" do
    post session_path,
         params: {
           email_address: @user.email_address,
           password: "wrong"
         },
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    assert_response :unprocessable_entity
    assert_match "turbo-stream", @response.body
    assert_match "login_form", @response.body
    assert_nil cookies[:session_id]
  end

  test "create with remember_me unchecked still signs in" do
    post session_path,
         params: {
           email_address: @user.email_address,
           password: "password",
           remember_me: "0"
         }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
