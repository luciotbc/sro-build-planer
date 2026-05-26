require "test_helper"

class SkillGroupTest < ActiveSupport::TestCase
  let(:mastery) { create(:mastery) }
  let(:sg) { create(:skill_group, mastery:, max_skill_level: 2) }
  let(:sg_no_max) { create(:skill_group, mastery:, max_skill_level: nil) }
  let(:skill_1) { create(:skill, skill_group: sg, skill_level: 1) }
  let(:skill_2) { create(:skill, skill_group: sg, skill_level: 2) }

  it "valid with external_group_code and mastery" do
    skill_group = SkillGroup.new(external_group_code: "SG001", mastery:)

    assert skill_group.valid?
  end

  it "invalid without external_group_code" do
    skill_group = SkillGroup.new(mastery:)

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:external_group_code], "can't be blank"
  end

  it "invalid with duplicate external_group_code" do
    skill_group =
      SkillGroup.new(external_group_code: sg.external_group_code, mastery:)

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:external_group_code],
                    "has already been taken"
  end

  it "invalid without mastery" do
    skill_group = SkillGroup.new(external_group_code: "SG002")

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:mastery], "must exist"
  end

  it "belongs_to mastery association" do
    assert_equal mastery, sg.mastery
  end

  it "valid without skill_series (optional)" do
    new_sg = SkillGroup.new(external_group_code: "SG_OPT_001", mastery:)

    assert new_sg.valid?
  end

  it "belongs_to skill_series when present" do
    assert_respond_to sg, :skill_series
  end

  it "has_many skill_group_requirements" do
    assert_respond_to sg, :skill_group_requirements
  end

  it "has_many character_skills" do
    assert_respond_to sg, :character_skills
  end

  it "skill_at_level returns the skill matching the given level" do
    skill_1
    skill_2

    assert_equal skill_1, sg.skill_at_level(1)
    assert_equal skill_2, sg.skill_at_level(2)
  end

  it "skill_at_level returns nil when no skill exists at that level" do
    assert_nil sg_no_max.skill_at_level(0)
  end

  it "skill_at_level returns nil for level 0 when no skill at level 0" do
    skill_1
    skill_2

    assert_nil sg.skill_at_level(0)
  end

  it "skill_at_level raises ArgumentError for negative level" do
    skill_1
    skill_2

    assert_raises(ArgumentError) { sg.skill_at_level(-1) }
  end

  it "skill_at_level raises ArgumentError with descriptive message for negative level" do
    skill_1
    skill_2
    error = assert_raises(ArgumentError) { sg.skill_at_level(-1) }

    assert_match "-1", error.message
  end

  it "skill_at_level raises ArgumentError when level exceeds max_skill_level" do
    skill_1
    skill_2

    assert_raises(ArgumentError) { sg.skill_at_level(3) }
  end

  it "skill_at_level raises ArgumentError with descriptive message for level above max" do
    skill_1
    skill_2
    error = assert_raises(ArgumentError) { sg.skill_at_level(3) }

    assert_match "3", error.message
    assert_match sg.max_skill_level.to_s, error.message
  end

  it "skill_at_level allows any non-negative level when max_skill_level is nil" do
    assert_nil sg_no_max.max_skill_level
    assert_nil sg_no_max.skill_at_level(99)
  end
end
