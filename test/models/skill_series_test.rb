require "test_helper"

class SkillSeriesTest < ActiveSupport::TestCase
  let(:mastery) { create(:mastery) }
  let(:series) { create(:skill_series, mastery:) }

  it "valid with mastery" do
    assert SkillSeries.new(mastery:).valid?
  end

  it "invalid without mastery" do
    ss = SkillSeries.new

    assert_not ss.valid?
    assert_includes ss.errors[:mastery], "must exist"
  end

  it "belongs_to mastery association" do
    assert_equal mastery, series.mastery
  end

  it "has_many skill_groups" do
    assert_respond_to series, :skill_groups
  end
end
