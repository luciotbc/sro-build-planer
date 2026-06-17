require "test_helper"

class TopbarTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  describe "shared/topbar partial" do
    it "renders the header element" do
      render partial: "shared/topbar"
      assert_select "header"
    end

    it "renders the brand link pointing to root" do
      render partial: "shared/topbar"
      assert_select "a[href=?]", root_path
    end

    it "renders the brand logo image" do
      render partial: "shared/topbar"
      assert_select "img[src*='icon']"
    end

    it "renders the SRO Lab wordmark" do
      render partial: "shared/topbar"
      assert_select "header", /SRO Lab/
    end

    it "renders the actions slot empty by default" do
      render partial: "shared/topbar"
      assert_select "div.flex.items-center", text: ""
    end

    it "renders content passed to the actions slot" do
      render partial: "shared/topbar",
             locals: {
               actions: "<button>Log in</button>".html_safe
             }
      assert_select "button", text: "Log in"
    end
  end
end
