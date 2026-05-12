require "test_helper"

class SkillSeriesTest < ActiveSupport::TestCase
  test "valid with mastery" do
    assert SkillSeries.new(mastery: masteries(:blade_sword)).valid?
  end

  test "invalid without mastery" do
    ss = SkillSeries.new

    assert_not ss.valid?
    assert_includes ss.errors[:mastery], "must exist"
  end

  test "belongs_to mastery association" do
    assert_equal masteries(:blade_sword), skill_series(:one).mastery
  end

  test "has_many skill_groups" do
    assert_respond_to skill_series(:one), :skill_groups
  end
end
