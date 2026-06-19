require "test_helper"

class StatsSummaryTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  def summary(overrides = {})
    {
      skill_points: {
        current: 1000,
        delta: 500,
        planned: 1500
      },
      mastery_total: {
        current: 50,
        delta: 30,
        planned: 80
      },
      required_level: {
        current: 20,
        delta: 10,
        planned: 30
      }
    }.merge(overrides)
  end

  describe "shared/stats_summary partial" do
    it "renders three stat rows" do
      render partial: "shared/stats_summary", locals: { summary: summary }
      assert_select ".stat-line", count: 3
    end

    it "renders skill points label" do
      render partial: "shared/stats_summary", locals: { summary: summary }
      assert_select ".stat-label", text: /Skill points/i
    end

    it "renders mastery total label" do
      render partial: "shared/stats_summary", locals: { summary: summary }
      assert_select ".stat-label", text: /Mastery total/i
    end

    it "renders required level label" do
      render partial: "shared/stats_summary", locals: { summary: summary }
      assert_select ".stat-label", text: /Required level/i
    end

    it "renders current skill points value" do
      render partial: "shared/stats_summary", locals: { summary: summary }
      assert_match "1000", rendered
    end

    it "renders planned skill points value" do
      render partial: "shared/stats_summary", locals: { summary: summary }
      assert_match "1500", rendered
    end

    it "renders all zeros when summary has zero values" do
      zero = {
        skill_points: {
          current: 0,
          delta: 0,
          planned: 0
        },
        mastery_total: {
          current: 0,
          delta: 0,
          planned: 0
        },
        required_level: {
          current: 0,
          delta: 0,
          planned: 0
        }
      }
      render partial: "shared/stats_summary", locals: { summary: zero }
      assert_select ".stat-line", count: 3
      assert rendered.include?("0"),
             "expected zeros to appear in rendered output"
    end

    it "renders negative delta without crashing" do
      neg =
        summary.merge(
          skill_points: {
            current: 1500,
            delta: -500,
            planned: 1000
          }
        )
      render partial: "shared/stats_summary", locals: { summary: neg }
      assert_match "-500", rendered
    end
  end
end
