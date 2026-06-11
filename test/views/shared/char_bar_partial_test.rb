require "test_helper"

class CharBarPartialTest < ActionView::TestCase
  describe "shared/char_bar" do
    it "renders name, race and level cap" do
      render partial: "shared/char_bar",
             locals: {
               name: "BuckTBC",
               race: "Chinese",
               level_cap: 110
             }

      assert_select "h1.text-brass-hi", text: "BuckTBC"
      assert_select "span", text: "Chinese"
      assert_select "span.tnum", text: "110"
    end
  end
end
