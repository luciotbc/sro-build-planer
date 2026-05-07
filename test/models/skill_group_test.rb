require "test_helper"

class SkillGroupTest < ActiveSupport::TestCase
  test "valid with external_group_code and mastery" do
    mastery = masteries(:blade_sword)
    skill_group = SkillGroup.new(external_group_code: "SG001", mastery: mastery)

    assert skill_group.valid?
  end

  test "invalid without external_group_code" do
    mastery = masteries(:blade_sword)
    skill_group = SkillGroup.new(mastery: mastery)

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:external_group_code], "can't be blank"
  end

  test "invalid with duplicate external_group_code" do
    existing_skill_group = skill_groups(:sword_mastery_skills)
    mastery = masteries(:blade_sword)
    skill_group = SkillGroup.new(external_group_code: existing_skill_group.external_group_code, mastery: mastery)

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:external_group_code], "has already been taken"
  end

  test "invalid without mastery" do
    skill_group = SkillGroup.new(external_group_code: "SG002")

    assert_not skill_group.valid?
    assert_includes skill_group.errors[:mastery], "must exist"
  end

  test "belongs_to mastery association" do
    skill_group = skill_groups(:sword_mastery_skills)
    assert_equal masteries(:blade_sword), skill_group.mastery
  end
end
