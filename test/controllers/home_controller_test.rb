require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  describe "anonymous visitor" do
    it "renders the hero pitch" do
      get root_url
      assert_select "h1", text: /Plan your build/
    end

    it "renders a live preview screenshot" do
      get root_url
      assert_select "img[src*=demo_build]"
    end

    it "renders the feature cards" do
      get root_url
      assert_select "h3", text: "Full skill trees"
      assert_select "h3", text: "Exact SP math"
      assert_select "h3", text: "Multiple characters"
    end

    it "renders a bottom call-to-action signup trigger" do
      get root_url
      assert_select "button[data-action*='auth#showSignup']", minimum: 1
    end

    it "does not render the create-character modal" do
      get root_url
      assert_select "#new-character-dialog", count: 0
    end
  end

  describe "authenticated visitor with no characters" do
    it "renders the create-character modal instead of the landing page" do
      user = create(:user, :confirmed)
      sign_in_as(user)

      get root_url
      assert_response :success
      assert_select "#new-character-dialog"
      assert_select "h1", text: /Plan your build/, count: 0
    end
  end

  describe "authenticated visitor with characters" do
    it "redirects to their most recent character" do
      user = create(:user, :confirmed)
      character = create(:character, user: user, race: races(:chinese))
      sign_in_as(user)

      get root_url
      assert_redirected_to character_path(character)
    end
  end
end
