require "test_helper"

class CharacterSkillTest < ActiveSupport::TestCase
  let(:race) { create(:race) }
  let(:mastery) { create(:mastery, race:) }
  let(:character) { create(:character, race:) }
  let(:another_character) { create(:character, race:) }
  let(:skill_group) { create(:skill_group, mastery:) }
  let(:other_skill_group) { create(:skill_group, mastery:) }
  let(:skill_1) { create(:skill, skill_group:, skill_level: 1) }
  let(:cs) do
    create(
      :character_skill,
      character:,
      skill_group:,
      current_skill_level: 1,
      target_skill_level: 1
    )
  end

  it "valid with character and skill_group" do
    new_cs = CharacterSkill.new(character:, skill_group: other_skill_group)

    assert new_cs.valid?
  end

  it "invalid without character" do
    new_cs = CharacterSkill.new(skill_group:)

    assert_not new_cs.valid?
    assert_includes new_cs.errors[:character], "must exist"
  end

  it "invalid without skill_group" do
    new_cs = CharacterSkill.new(character:)

    assert_not new_cs.valid?
    assert_includes new_cs.errors[:skill_group], "must exist"
  end

  it "invalid with duplicate skill_group for the same character" do
    cs
    new_cs = CharacterSkill.new(character:, skill_group:)

    assert_not new_cs.valid?
    assert_includes new_cs.errors[:skill_group_id], "has already been taken"
  end

  it "valid with same skill_group for a different character" do
    cs
    new_cs = CharacterSkill.new(character: another_character, skill_group:)

    assert new_cs.valid?
  end

  it "belongs_to character association" do
    assert_equal character, cs.character
  end

  it "belongs_to skill_group association" do
    assert_equal skill_group, cs.skill_group
  end

  it "current_skill returns the skill at current_skill_level" do
    skill_1

    assert_equal skill_1, cs.current_skill
  end

  it "current_skill returns nil when current_skill_level is 0" do
    new_cs =
      CharacterSkill.new(character:, skill_group:, current_skill_level: 0)

    assert_nil new_cs.current_skill
  end

  it "current_skill returns nil when current_skill_level is nil" do
    new_cs = CharacterSkill.new(character:, skill_group:)

    assert_nil new_cs.current_skill
  end

  it "target_skill returns the skill at target_skill_level" do
    skill_1

    assert_equal skill_1, cs.target_skill
  end

  it "target_skill returns nil when target_skill_level is 0" do
    new_cs = CharacterSkill.new(character:, skill_group:, target_skill_level: 0)

    assert_nil new_cs.target_skill
  end

  it "target_skill returns nil when target_skill_level is nil" do
    new_cs = CharacterSkill.new(character:, skill_group:)

    assert_nil new_cs.target_skill
  end
end
