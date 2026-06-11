require "test_helper"

class StatRowPartialTest < ActionView::TestCase
  describe "shared/stat_row" do
    it "renders current, delta and planned values" do
      render partial: "shared/stat_row",
             locals: {
               label: "Mastery total",
               current: 210,
               planned: 440
             }

      assert_select "span", text: "Mastery total"
      assert_select "span.text-white", text: "210"
      assert_select "span.text-green", text: "230"
      assert_select "span.text-brass-hi", text: "440"
    end

    it "omits the delta when current equals planned" do
      render partial: "shared/stat_row",
             locals: {
               label: "Level",
               current: 92,
               planned: 92
             }

      assert_select "span.text-green", false
      assert_select "span.text-brass-hi", text: "92"
    end

    it "formats values with delimiters when format is comma" do
      render partial: "shared/stat_row",
             locals: {
               label: "Skill points",
               current: 3_210_000,
               planned: 6_440_000,
               format: :comma
             }

      assert_select "span.text-white", text: "3,210,000"
      assert_select "span.text-brass-hi", text: "6,440,000"
    end

    it "renders a negative delta in red" do
      render partial: "shared/stat_row",
             locals: {
               label: "Points",
               current: 100,
               planned: 80
             }

      assert_select "span.text-red", text: "20"
    end
  end
end
