require "test_helper"

class TopbarAuthTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = races(:chinese)
    create(:character, user: @user, race: @race, name: "Blade Lord")
    create(:character, user: @user, race: @race, name: "Cold Mage")
  end

  it "shows Log in when unauthenticated" do
    get new_session_path
    assert_response :success
    assert_select "a, button, input[type='submit']", text: /Log in/i
  end

  it "shows Characters pill with count when authenticated" do
    sign_in_as @user
    get root_path
    follow_redirect! while response.redirect?
    assert_select ".chars-pill .count", text: "2"
  end

  it "shows Log out when authenticated" do
    sign_in_as @user
    get root_path
    follow_redirect! while response.redirect?
    assert_select "form[action=?]", session_path
  end
end
