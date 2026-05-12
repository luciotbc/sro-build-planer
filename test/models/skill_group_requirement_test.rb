require "test_helper"

class SkillGroupRequirementTest < ActiveSupport::TestCase
  test "valid with skill_group and required_group" do
    req = SkillGroupRequirement.new(
      skill_group: skill_groups(:wizard_skills),
      required_group: skill_groups(:cold_force_skills)
    )

    assert req.valid?
  end

  test "invalid without skill_group" do
    req = SkillGroupRequirement.new(required_group: skill_groups(:sword_mastery_skills))

    assert_not req.valid?
    assert_includes req.errors[:skill_group], "must exist"
  end

  test "invalid without required_group" do
    req = SkillGroupRequirement.new(skill_group: skill_groups(:wizard_skills))

    assert_not req.valid?
    assert_includes req.errors[:required_group], "must exist"
  end

  test "belongs_to skill_group association" do
    assert_equal skill_groups(:spear_mastery_skills), skill_group_requirements(:one).skill_group
  end

  test "belongs_to required_group resolves to a SkillGroup" do
    req = skill_group_requirements(:one)

    assert_instance_of SkillGroup, req.required_group
    assert_equal skill_groups(:sword_mastery_skills), req.required_group
  end
end
