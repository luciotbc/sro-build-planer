require "test_helper"

class RegistrationPasswordRulesTest < ActionDispatch::IntegrationTest
  test "registration page renders the live password rules panel" do
    get new_registration_url

    assert_response :success
    assert_select "#registration_form [data-controller~=?]", "password-rules"
    assert_select "#registration_form input[name=?][data-password-rules-target=?]",
                  "password",
                  "password"
    assert_select "#registration_form input[name=?][data-password-rules-target=?]",
                  "password_confirmation",
                  "confirmation"
    assert_select "#registration_form .password-rules[hidden]"
    assert_select "#registration_form .password-rules li[data-rule]", count: 4
  end

  test "signup modal on the home page renders the same rules panel" do
    get root_url

    assert_response :success
    assert_select "dialog[data-auth-target='signup'] .password-rules[hidden]"
    assert_select "dialog[data-auth-target='signup'] .password-rules li[data-rule]",
                  count: 4
  end
end
