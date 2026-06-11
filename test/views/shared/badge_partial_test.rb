require "test_helper"

class BadgePartialTest < ActionView::TestCase
  describe "shared/badge" do
    it "renders a neutral badge by default" do
      render partial: "shared/badge", locals: { label: "active" }

      assert_select "span", text: "active"
    end

    it "renders the planned tone with brass styling" do
      render partial: "shared/badge",
             locals: {
               label: "Planned",
               tone: :planned
             }

      assert_select "span.text-brass-hi", text: "Planned"
    end

    it "renders the max tone" do
      render partial: "shared/badge", locals: { label: "MAX", tone: :max }

      assert_select "span.bg-brass", text: "MAX"
    end
  end
end
