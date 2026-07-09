require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  let(:valid_params) do
    {
      email_address: "signup@example.com",
      password: "Password1",
      password_confirmation: "Password1",
      terms: "1",
      email_opt_in: "1"
    }
  end

  it "renders the sign-up page" do
    get new_registration_path
    assert_response :success
  end

  it "links the terms and privacy consent to the legal pages" do
    get new_registration_path

    assert_select "a[href=?]", terms_path
    assert_select "a[href=?]", privacy_path
  end

  it "creates a user and redirects home with the email stashed" do
    assert_difference "User.count", 1 do
      post registration_path, params: valid_params
    end

    assert_redirected_to root_path
    assert_equal "signup@example.com", flash[:registered_email]
    assert_enqueued_emails 1

    follow_redirect!
    assert_select "[data-auth-target=confirm]"
    assert_match "signup@example.com", response.body
  end

  it "records the marketing opt-in choice" do
    post registration_path, params: valid_params.merge(email_opt_in: "1")
    assert User.find_by(email_address: "signup@example.com").email_opt_in

    post registration_path,
         params:
           valid_params.merge(
             email_address: "second@example.com",
             email_opt_in: "0"
           )
    assert_not User.find_by(email_address: "second@example.com").email_opt_in
  end

  it "rejects sign-up when terms are not accepted" do
    assert_no_difference "User.count" do
      post registration_path,
           params: valid_params.merge(terms: "0"),
           as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_match "terms", response.body
  end

  it "re-renders with errors on invalid input" do
    assert_no_difference "User.count" do
      post registration_path,
           params: valid_params.merge(email_address: "nope"),
           as: :turbo_stream
    end

    assert_response :unprocessable_entity
    assert_no_enqueued_emails
  end
end
