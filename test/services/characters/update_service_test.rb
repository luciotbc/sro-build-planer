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
    @char = create(:character, race: @chinese_race, server_level_cap: 110)
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

  it "preserves name and server_level_cap when race changes" do
    original_name = @char.name
    original_cap = @char.server_level_cap

    Characters::UpdateService.call(@char, race_id: @european_race.id)

    @char.reload
    assert_equal original_name, @char.name
    assert_equal original_cap, @char.server_level_cap
    assert_equal @european_race.id, @char.race_id
  end

  # --------- server_level_cap -------------------------------------------------

  it "updates server_level_cap to a valid value" do
    result = Characters::UpdateService.call(@char, server_level_cap: 100)

    assert result.success?
    assert_equal 100, @char.reload.server_level_cap
  end

  it "fails with invalid server_level_cap" do
    result = Characters::UpdateService.call(@char, server_level_cap: 95)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Server level cap") }
  end

  it "fails when lowering server_level_cap below existing current_mastery_level" do
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 100
    )

    result = Characters::UpdateService.call(@char, server_level_cap: 90)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Blade") }
  end

  it "fails when lowering server_level_cap below existing target_mastery_level" do
    CharacterMastery.create!(
      character: @char,
      mastery: @spear_mastery,
      target_mastery_level: 100
    )

    result = Characters::UpdateService.call(@char, server_level_cap: 90)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Spear") }
  end

  it "lists all incompatible masteries when server_level_cap is lowered" do
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 100
    )
    CharacterMastery.create!(
      character: @char,
      mastery: @spear_mastery,
      current_mastery_level: 95
    )

    result = Characters::UpdateService.call(@char, server_level_cap: 90)

    assert_not result.success?
    error = result.errors.first
    assert_match "Blade", error
    assert_match "Spear", error
  end

  it "succeeds when masteries are at or below new server_level_cap" do
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 90
    )

    result = Characters::UpdateService.call(@char, server_level_cap: 90)

    assert result.success?
    assert_equal 90, @char.reload.server_level_cap
  end

  it "skips mastery cap check when race is also changing" do
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 100
    )

    result =
      Characters::UpdateService.call(
        @char,
        race_id: @european_race.id,
        server_level_cap: 90
      )

    assert result.success?
    assert_equal 0, @char.character_masteries.count
  end

  # --------- general safeguards -----------------------------------------------

  it "does not save anything on failure" do
    original_name = @char.name

    result =
      Characters::UpdateService.call(@char, name: "", server_level_cap: 90)

    assert_not result.success?
    assert_equal original_name, @char.reload.name
    assert_equal 110, @char.server_level_cap
  end
end
