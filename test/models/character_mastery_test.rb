require "test_helper"

class CharacterMasteryTest < ActiveSupport::TestCase
  let(:race) { create(:race) }
  let(:character) { create(:character, race:, server_level_cap: 110) }
  let(:mastery) { create(:mastery, race:) }

  it "valid with character and mastery" do
    cm = CharacterMastery.new(character:, mastery:)

    assert cm.valid?
  end

  it "invalid without character" do
    cm = CharacterMastery.new(mastery:)

    assert_not cm.valid?
    assert_includes cm.errors[:character], "must exist"
  end

  it "invalid without mastery" do
    cm = CharacterMastery.new(character:)

    assert_not cm.valid?
    assert_includes cm.errors[:mastery], "must exist"
  end

  it "belongs_to character association" do
    cm = CharacterMastery.create!(character:, mastery:)

    assert_equal character, cm.character
  end

  it "belongs_to mastery association" do
    cm = CharacterMastery.create!(character:, mastery:)

    assert_equal mastery, cm.mastery
  end

  it "valid with nil mastery levels" do
    cm = CharacterMastery.new(character:, mastery:)

    assert cm.valid?
  end

  it "valid with mastery levels at server_level_cap" do
    cm =
      CharacterMastery.new(
        character:,
        mastery:,
        current_mastery_level: 0,
        target_mastery_level: character.server_level_cap
      )

    assert cm.valid?
  end

  it "invalid with current_mastery_level below 0" do
    cm = CharacterMastery.new(character:, mastery:, current_mastery_level: -1)

    assert_not cm.valid?
    assert_includes cm.errors[:current_mastery_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with current_mastery_level above server_level_cap" do
    cm =
      CharacterMastery.new(
        character:,
        mastery:,
        current_mastery_level: character.server_level_cap + 1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:current_mastery_level],
                    "must be less than or equal to #{character.server_level_cap}"
  end

  it "invalid with target_mastery_level below 0" do
    cm = CharacterMastery.new(character:, mastery:, target_mastery_level: -1)

    assert_not cm.valid?
    assert_includes cm.errors[:target_mastery_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with target_mastery_level above server_level_cap" do
    cm =
      CharacterMastery.new(
        character:,
        mastery:,
        target_mastery_level: character.server_level_cap + 1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:target_mastery_level],
                    "must be less than or equal to #{character.server_level_cap}"
  end

  # ---------- level cache recompute via callback ------------------------------

  it "creates character mastery and triggers level recompute" do
    CharacterMastery.create!(
      character:,
      mastery:,
      current_mastery_level: 50,
      target_mastery_level: 80
    )

    character.reload
    assert_equal 50, character.current_level
    assert_equal 80, character.target_level
  end

  it "updating mastery level recomputes character levels" do
    cm =
      CharacterMastery.create!(
        character:,
        mastery:,
        current_mastery_level: 50,
        target_mastery_level: 80
      )
    cm.update!(current_mastery_level: 60)

    assert_equal 60, character.reload.current_level
  end

  it "destroying mastery recomputes character levels to 0 when none remain" do
    cm =
      CharacterMastery.create!(
        character:,
        mastery:,
        current_mastery_level: 50,
        target_mastery_level: 80
      )
    cm.destroy!

    character.reload
    assert_equal 0, character.current_level
    assert_equal 0, character.target_level
  end

  it "character current_level reflects max across all masteries" do
    mastery_b = create(:mastery, race:)
    CharacterMastery.create!(
      character:,
      mastery:,
      current_mastery_level: 30,
      target_mastery_level: 0
    )
    CharacterMastery.create!(
      character:,
      mastery: mastery_b,
      current_mastery_level: 70,
      target_mastery_level: 0
    )

    assert_equal 70, character.reload.current_level
  end
end
