require "test_helper"

class Characters::UpdateServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @european_race = create(:race)
    @blade_mastery =
      create(
        :mastery,
        name: "Blade",
        mastery_type: "Weapon",
        race: @chinese_race
      )
    @spear_mastery =
      create(
        :mastery,
        name: "Spear",
        mastery_type: "Weapon",
        race: @chinese_race
      )
    @cold_sg = create(:skill_group, mastery: @blade_mastery)
    @char =
      create(:character, race: @chinese_race, current_level: 1, target_level: 1)
  end

  # --------- name -------------------------------------------------------------

  it "updates the character name" do
    result = Characters::UpdateService.call(@char, name: "Updated Name")

    assert result.success?
    assert_equal "Updated Name", @char.reload.name
  end

  it "fails with blank name" do
    result = Characters::UpdateService.call(@char, name: "")

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  it "fails with nil name" do
    result = Characters::UpdateService.call(@char, name: nil)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  # --------- race change ------------------------------------------------------

  it "updates race and purges masteries and skills when race changes" do
    CharacterMastery.create!(character: @char, mastery: @blade_mastery)
    CharacterSkill.create!(character: @char, skill_group: @cold_sg)

    result = Characters::UpdateService.call(@char, race_id: @european_race.id)

    assert result.success?
    assert_equal @european_race.id, @char.reload.race_id
    assert_equal 0, @char.character_masteries.count
    assert_equal 0, @char.character_skills.count
  end

  it "fails with non-existent race_id" do
    result = Characters::UpdateService.call(@char, race_id: 0)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Race") }
  end

  it "does not change race when race_id is unchanged" do
    original_race_id = @char.race_id

    result = Characters::UpdateService.call(@char, race_id: original_race_id)

    assert result.success?
    assert_equal original_race_id, @char.reload.race_id
  end

  # --------- level changes ----------------------------------------------------

  it "updates current_level and target_level" do
    result =
      Characters::UpdateService.call(
        @char,
        current_level: 50,
        target_level: 100
      )

    assert result.success?
    assert_equal 50, @char.reload.current_level
    assert_equal 100, @char.reload.target_level
  end

  it "accepts level of 0" do
    result = Characters::UpdateService.call(@char, current_level: 0)

    assert result.success?
    assert_equal 0, @char.reload.current_level
  end

  it "fails with current_level above MAX_LEVEL" do
    result =
      Characters::UpdateService.call(
        @char,
        current_level: Character::MAX_LEVEL + 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Current level") }
  end

  it "fails with negative target_level" do
    result = Characters::UpdateService.call(@char, target_level: -1)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Target level") }
  end

  # --------- mastery compatibility ---------------------------------------------

  it "fails when reducing current_level below existing current_mastery_level" do
    @char.update!(current_level: 80)
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 60
    )

    result = Characters::UpdateService.call(@char, current_level: 50)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Blade") }
  end

  it "fails when reducing target_level below existing target_mastery_level" do
    @char.update!(target_level: 100)
    CharacterMastery.create!(
      character: @char,
      mastery: @spear_mastery,
      target_mastery_level: 90
    )

    result = Characters::UpdateService.call(@char, target_level: 70)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Spear") }
  end

  it "lists all incompatible masteries in the error" do
    @char.update!(current_level: 80)
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 60
    )
    CharacterMastery.create!(
      character: @char,
      mastery: @spear_mastery,
      current_mastery_level: 70
    )

    result = Characters::UpdateService.call(@char, current_level: 50)

    assert_not result.success?
    error = result.errors.first
    assert_match "Blade", error
    assert_match "Spear", error
  end

  it "succeeds when new level equals existing mastery level" do
    @char.update!(current_level: 80)
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 50
    )

    result = Characters::UpdateService.call(@char, current_level: 50)

    assert result.success?
  end

  it "preserves other character fields when race changes" do
    original_name = @char.name
    original_current_level = @char.current_level

    Characters::UpdateService.call(@char, race_id: @european_race.id)

    @char.reload
    assert_equal original_name, @char.name
    assert_equal original_current_level, @char.current_level
    assert_equal @european_race.id, @char.race_id
  end

  it "skips mastery check when race is also changing" do
    @char.update!(current_level: 80)
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 60
    )

    result =
      Characters::UpdateService.call(
        @char,
        race_id: @european_race.id,
        current_level: 50
      )

    assert result.success?
    assert_equal 0, @char.character_masteries.count
  end

  it "does not save anything on failure" do
    original_name = @char.name

    result = Characters::UpdateService.call(@char, name: "", current_level: 50)

    assert_not result.success?
    assert_equal original_name, @char.reload.name
    assert_not_equal 50, @char.current_level
  end
end
