require "test_helper"

class Characters::UpdateServiceTest < ActiveSupport::TestCase
  # ───────── name ─────────────────────────────────────────────────────────────

  test "updates the character name" do
    result =
      Characters::UpdateService.call(characters(:one), name: "Updated Name")

    assert result.success?
    assert_equal "Updated Name", characters(:one).reload.name
  end

  test "fails with blank name" do
    result = Characters::UpdateService.call(characters(:one), name: "")

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  test "fails with nil name" do
    result = Characters::UpdateService.call(characters(:one), name: nil)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Name") }
  end

  # ───────── race change ──────────────────────────────────────────────────────

  test "updates race and purges masteries and skills when race changes" do
    char = characters(:one)
    CharacterMastery.create!(character: char, mastery: masteries(:blade_sword))
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:cold_force_skills)
    )

    result = Characters::UpdateService.call(char, race_id: races(:european).id)

    assert result.success?
    assert_equal races(:european).id, char.reload.race_id
    assert_equal 0, char.character_masteries.count
    assert_equal 0, char.character_skills.count
  end

  test "fails with non-existent race_id" do
    result = Characters::UpdateService.call(characters(:one), race_id: 0)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Race") }
  end

  test "does not change race when race_id is unchanged" do
    char = characters(:one)
    original_race_id = char.race_id

    result = Characters::UpdateService.call(char, race_id: original_race_id)

    assert result.success?
    assert_equal original_race_id, char.reload.race_id
  end

  # ───────── level changes ────────────────────────────────────────────────────

  test "updates current_level and target_level" do
    result =
      Characters::UpdateService.call(
        characters(:one),
        current_level: 50,
        target_level: 100
      )

    assert result.success?
    assert_equal 50, characters(:one).reload.current_level
    assert_equal 100, characters(:one).reload.target_level
  end

  test "accepts level of 0" do
    result = Characters::UpdateService.call(characters(:one), current_level: 0)

    assert result.success?
    assert_equal 0, characters(:one).reload.current_level
  end

  test "fails with current_level above MAX_LEVEL" do
    result =
      Characters::UpdateService.call(
        characters(:one),
        current_level: Character::MAX_LEVEL + 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Current level") }
  end

  test "fails with negative target_level" do
    result = Characters::UpdateService.call(characters(:one), target_level: -1)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Target level") }
  end

  # ───────── mastery compatibility ─────────────────────────────────────────────

  test "fails when reducing current_level below existing current_mastery_level" do
    char = characters(:one)
    char.update!(current_level: 80)
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:blade_sword),
      current_mastery_level: 60
    )

    result = Characters::UpdateService.call(char, current_level: 50)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Blade") }
  end

  test "fails when reducing target_level below existing target_mastery_level" do
    char = characters(:one)
    char.update!(target_level: 100)
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:spear),
      target_mastery_level: 90
    )

    result = Characters::UpdateService.call(char, target_level: 70)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Spear") }
  end

  test "lists all incompatible masteries in the error" do
    char = characters(:one)
    char.update!(current_level: 80)
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:blade_sword),
      current_mastery_level: 60
    )
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:spear),
      current_mastery_level: 70
    )

    result = Characters::UpdateService.call(char, current_level: 50)

    assert_not result.success?
    error = result.errors.first
    assert_match "Blade", error
    assert_match "Spear", error
  end

  test "succeeds when new level equals existing mastery level" do
    char = characters(:one)
    char.update!(current_level: 80)
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:blade_sword),
      current_mastery_level: 50
    )

    result = Characters::UpdateService.call(char, current_level: 50)

    assert result.success?
  end

  test "skips mastery check when race is also changing" do
    char = characters(:one)
    char.update!(current_level: 80)
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:blade_sword),
      current_mastery_level: 60
    )

    result =
      Characters::UpdateService.call(
        char,
        race_id: races(:european).id,
        current_level: 50
      )

    assert result.success?
    assert_equal 0, char.character_masteries.count
  end

  test "does not save anything on failure" do
    char = characters(:one)
    original_name = char.name

    result = Characters::UpdateService.call(char, name: "", current_level: 50)

    assert_not result.success?
    assert_equal original_name, char.reload.name
    assert_not_equal 50, char.current_level
  end
end
