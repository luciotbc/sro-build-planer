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

    describe ":sm variant" do
      it "renders label, current, and planned without border-t or padding wrapper" do
        render partial: "shared/stat_row",
               locals: {
                 label: "Skill points",
                 current: 100,
                 planned: 200,
                 size: :sm
               }

        assert_select "div.flex.items-baseline.justify-between"
        assert_select "span.text-\\[11px\\].font-bold.uppercase",
                      text: "Skill points"
        assert_select "span.text-white", text: "100"
        assert_select "span.text-brass-hi", text: "200"

        # Must not include border-t or padding present in the full-size variant
        assert_select "div.border-t", false
        assert_select "div.px-3\\.5", false
      end

      it "renders a positive delta with + prefix in green" do
        render partial: "shared/stat_row",
               locals: {
                 label: "SP",
                 current: 50,
                 planned: 80,
                 size: :sm
               }

        assert_select "span.text-green"
        rendered_html = rendered
        assert_match(/\+30/, rendered_html)
      end

      it "renders a negative delta with minus prefix in red" do
        render partial: "shared/stat_row",
               locals: {
                 label: "SP",
                 current: 80,
                 planned: 50,
                 size: :sm
               }

        assert_select "span.text-red"
        assert_select "span.text-green", false
      end

      it "omits the delta span when current equals planned" do
        render partial: "shared/stat_row",
               locals: {
                 label: "Level",
                 current: 90,
                 planned: 90,
                 size: :sm
               }

        assert_select "span.text-green", false
        assert_select "span.text-red", false
      end

      it "formats values with delimiters when format is comma" do
        render partial: "shared/stat_row",
               locals: {
                 label: "Skill points",
                 current: 1_000_000,
                 planned: 2_000_000,
                 format: :comma,
                 size: :sm
               }

        assert_select "span.text-white", text: "1,000,000"
        assert_select "span.text-brass-hi", text: "2,000,000"
      end
    end
  end
end
