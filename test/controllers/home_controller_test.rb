require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  it "renders the guest landing with a login call to action" do
    get root_url

    assert_response :success
    assert_select "a", text: "Log in"
  end

  it "prompts a logged in user without characters to create one" do
    sign_in_as(create(:user))

    get root_url

    assert_response :success
    assert_match "New character", response.body
  end
end
