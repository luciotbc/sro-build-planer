require "test_helper"

class CharacterMasteryTest < ActiveSupport::TestCase
  let(:race) { create(:race) }
  let(:character) { create(:character, race:) }
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

  it "valid with mastery levels within range" do
    cm =
      CharacterMastery.new(
        character:,
        mastery:,
        current_mastery_level: 0,
        target_mastery_level: Character::MAX_LEVEL
      )

    assert cm.valid?
  end

  it "invalid with current_mastery_level below 0" do
    cm = CharacterMastery.new(character:, mastery:, current_mastery_level: -1)

    assert_not cm.valid?
    assert_includes cm.errors[:current_mastery_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with current_mastery_level above MAX_LEVEL" do
    cm =
      CharacterMastery.new(
        character:,
        mastery:,
        current_mastery_level: Character::MAX_LEVEL + 1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:current_mastery_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end

  it "invalid with target_mastery_level below 0" do
    cm = CharacterMastery.new(character:, mastery:, target_mastery_level: -1)

    assert_not cm.valid?
    assert_includes cm.errors[:target_mastery_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with target_mastery_level above MAX_LEVEL" do
    cm =
      CharacterMastery.new(
        character:,
        mastery:,
        target_mastery_level: Character::MAX_LEVEL + 1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:target_mastery_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end
end
