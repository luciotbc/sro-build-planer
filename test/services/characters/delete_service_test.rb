require "test_helper"

class Characters::DeleteServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @european_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @spear_mastery = create(:mastery, race: @chinese_race)
    @sword_sg = create(:skill_group, mastery: @blade_mastery)
    @cold_sg = create(:skill_group, mastery: @blade_mastery)
    @char = create(:character, race: @chinese_race)
    @char2 = create(:character, race: @european_race)
  end

  it "deletes the character" do
    assert_difference "Character.count", -1 do
      Characters::DeleteService.call(@char)
    end
  end

  it "returns a successful ServiceResult" do
    result = Characters::DeleteService.call(@char2)

    assert result.success?
    assert_nil result.data
    assert_empty result.errors
  end

  it "hard-deletes all CharacterSkills before deleting the character" do
    CharacterSkill.create!(character: @char, skill_group: @cold_sg)
    assert @char.character_skills.count >= 1

    Characters::DeleteService.call(@char)

    assert_equal 0, CharacterSkill.where(character_id: @char.id).count
  end

  it "hard-deletes all CharacterMasteries before deleting the character" do
    CharacterMastery.create!(character: @char, mastery: @blade_mastery)

    assert_difference "CharacterMastery.count", -1 do
      Characters::DeleteService.call(@char)
    end
  end

  it "deletes character with multiple masteries and skills" do
    CharacterMastery.create!(character: @char, mastery: @blade_mastery)
    CharacterMastery.create!(character: @char, mastery: @spear_mastery)
    CharacterSkill.create!(character: @char, skill_group: @cold_sg)

    result = Characters::DeleteService.call(@char)

    assert result.success?
    assert_not Character.exists?(@char.id)
    assert_equal 0, CharacterMastery.where(character_id: @char.id).count
    assert_equal 0, CharacterSkill.where(character_id: @char.id).count
  end
end
