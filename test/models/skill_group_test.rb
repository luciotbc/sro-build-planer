require "test_helper"

class SkillGroupTest < ActiveSupport::TestCase
  it "valid with external_group_code and mastery" do
    mastery = masteries(:blade_sword)
    skill_group = SkillGroup.new(external_group_code: "SG001", mastery: mastery)

    assert skill_group.valid?
  end

  it "invalid without external_group_code" do
    mastery = masteries(:blade_sword)
    skill_group = SkillGroup.new(mastery: mastery)

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:external_group_code], "can't be blank"
  end

  it "invalid with duplicate external_group_code" do
    existing_skill_group = skill_groups(:sword_mastery_skills)
    mastery = masteries(:blade_sword)
    skill_group =
      SkillGroup.new(
        external_group_code: existing_skill_group.external_group_code,
        mastery: mastery
      )

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
    assert_equal masteries(:blade_sword),
                 skill_groups(:sword_mastery_skills).mastery
  end

  it "valid without skill_series (optional)" do
    sg =
      SkillGroup.new(
        external_group_code: "SG_OPT_001",
        mastery: masteries(:blade_sword)
      )

    assert sg.valid?
  end

  it "belongs_to skill_series when present" do
    sg = skill_groups(:sword_mastery_skills)

    assert_respond_to sg, :skill_series
  end

  it "has_many skill_group_requirements" do
    assert_respond_to skill_groups(:sword_mastery_skills),
                      :skill_group_requirements
  end

  it "has_many character_skills" do
    assert_respond_to skill_groups(:sword_mastery_skills), :character_skills
  end

  it "skill_at_level returns the skill matching the given level" do
    sg = skill_groups(:sword_mastery_skills)

    assert_equal skills(:blade_passive_skill), sg.skill_at_level(1)
    assert_equal skills(:blade_active_skill), sg.skill_at_level(2)
  end

  it "skill_at_level returns nil when no skill exists at that level" do
    sg = skill_groups(:spear_mastery_skills)

    assert_nil sg.skill_at_level(0)
  end

  it "skill_at_level returns nil for level 0 when no skill at level 0" do
    sg = skill_groups(:sword_mastery_skills)

    assert_nil sg.skill_at_level(0)
  end

  it "skill_at_level raises ArgumentError for negative level" do
    sg = skill_groups(:sword_mastery_skills)

    assert_raises(ArgumentError) { sg.skill_at_level(-1) }
  end

  it "skill_at_level raises ArgumentError with descriptive message for negative level" do
    sg = skill_groups(:sword_mastery_skills)
    error = assert_raises(ArgumentError) { sg.skill_at_level(-1) }

    assert_match "-1", error.message
  end

  it "skill_at_level raises ArgumentError when level exceeds max_skill_level" do
    sg = skill_groups(:sword_mastery_skills)

    assert_raises(ArgumentError) { sg.skill_at_level(3) }
  end

  it "skill_at_level raises ArgumentError with descriptive message for level above max" do
    sg = skill_groups(:sword_mastery_skills)
    error = assert_raises(ArgumentError) { sg.skill_at_level(3) }

    assert_match "3", error.message
    assert_match sg.max_skill_level.to_s, error.message
  end

  it "skill_at_level allows any non-negative level when max_skill_level is nil" do
    sg = skill_groups(:spear_mastery_skills)

    assert_nil sg.max_skill_level
    assert_nil sg.skill_at_level(99)
  end
end
