require "test_helper"

class TopbarPartialTest < ActionView::TestCase
  describe "shared/topbar" do
    it "renders the brand mark linking to root" do
      render partial: "shared/topbar"

      assert_select "header" do
        assert_select "a[href=?]", "/" do
          assert_select "span", text: "S"
          assert_select "span", text: "Skill Planner"
        end
      end
    end

    it "renders custom title and actions" do
      render partial: "shared/topbar",
             locals: {
               title: "SRO Builder",
               actions: content_tag(:button, "Log in", class: "btn-primary")
             }

      assert_select "span", text: "SRO Builder"
      assert_select "button.btn-primary", text: "Log in"
    end
  end
end
