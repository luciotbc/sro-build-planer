require "test_helper"

class Characters::DeleteServiceTest < ActiveSupport::TestCase
  it "deletes the character" do
    char = characters(:one)

    assert_difference "Character.count", -1 do
      Characters::DeleteService.call(char)
    end
  end

  it "returns a successful ServiceResult" do
    result = Characters::DeleteService.call(characters(:two))

    assert result.success?
    assert_nil result.data
    assert_empty result.errors
  end

  it "hard-deletes all CharacterSkills before deleting the character" do
    char = characters(:one)
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:cold_force_skills)
    )
    assert char.character_skills.count >= 1

    Characters::DeleteService.call(char)

    assert_equal 0, CharacterSkill.where(character_id: char.id).count
  end

  it "hard-deletes all CharacterMasteries before deleting the character" do
    char = characters(:one)
    CharacterMastery.create!(character: char, mastery: masteries(:blade_sword))

    assert_difference "CharacterMastery.count", -1 do
      Characters::DeleteService.call(char)
    end
  end

  it "deletes character with multiple masteries and skills" do
    char = characters(:one)
    CharacterMastery.create!(character: char, mastery: masteries(:blade_sword))
    CharacterMastery.create!(character: char, mastery: masteries(:spear))
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:cold_force_skills)
    )

    result = Characters::DeleteService.call(char)

    assert result.success?
    assert_not Character.exists?(char.id)
    assert_equal 0, CharacterMastery.where(character_id: char.id).count
    assert_equal 0, CharacterSkill.where(character_id: char.id).count
  end
end
