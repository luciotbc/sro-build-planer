require "test_helper"

class CharacterSkillTest < ActiveSupport::TestCase
  test "valid with character and skill_group" do
    cs =
      CharacterSkill.new(
        character: characters(:one),
        skill_group: skill_groups(:cold_force_skills)
      )

    assert cs.valid?
  end

  test "invalid without character" do
    cs = CharacterSkill.new(skill_group: skill_groups(:sword_mastery_skills))

    assert_not cs.valid?
    assert_includes cs.errors[:character], "must exist"
  end

  test "invalid without skill_group" do
    cs = CharacterSkill.new(character: characters(:one))

    assert_not cs.valid?
    assert_includes cs.errors[:skill_group], "must exist"
  end

  test "invalid with duplicate skill_group for the same character" do
    existing = character_skills(:one)
    cs =
      CharacterSkill.new(
        character: existing.character,
        skill_group: existing.skill_group
      )

    assert_not cs.valid?
    assert_includes cs.errors[:skill_group_id], "has already been taken"
  end

  test "valid with same skill_group for a different character" do
    existing = character_skills(:one)
    cs =
      CharacterSkill.new(
        character: characters(:two),
        skill_group: existing.skill_group
      )

    assert cs.valid?
  end

  test "belongs_to character association" do
    assert_equal characters(:one), character_skills(:one).character
  end

  test "belongs_to skill_group association" do
    assert_equal skill_groups(:sword_mastery_skills),
                 character_skills(:one).skill_group
  end

  test "current_skill returns the skill at current_skill_level" do
    cs = character_skills(:one)

    assert_equal skills(:blade_passive_skill), cs.current_skill
  end

  test "current_skill returns nil when current_skill_level is 0" do
    cs =
      CharacterSkill.new(
        character: characters(:one),
        skill_group: skill_groups(:cold_force_skills),
        current_skill_level: 0
      )

    assert_nil cs.current_skill
  end

  test "current_skill returns nil when current_skill_level is nil" do
    cs =
      CharacterSkill.new(
        character: characters(:one),
        skill_group: skill_groups(:cold_force_skills)
      )

    assert_nil cs.current_skill
  end

  test "target_skill returns the skill at target_skill_level" do
    cs = character_skills(:one)

    assert_equal skills(:blade_passive_skill), cs.target_skill
  end

  test "target_skill returns nil when target_skill_level is 0" do
    cs =
      CharacterSkill.new(
        character: characters(:one),
        skill_group: skill_groups(:cold_force_skills),
        target_skill_level: 0
      )

    assert_nil cs.target_skill
  end

  test "target_skill returns nil when target_skill_level is nil" do
    cs =
      CharacterSkill.new(
        character: characters(:one),
        skill_group: skill_groups(:cold_force_skills)
      )

    assert_nil cs.target_skill
  end
end
