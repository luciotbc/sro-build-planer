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
end
