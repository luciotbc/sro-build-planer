require "test_helper"

class CharacterMasteryTest < ActiveSupport::TestCase
  it "valid with character and mastery" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert cm.valid?
  end

  it "invalid without character" do
    cm = CharacterMastery.new(mastery: masteries(:blade_sword))

    assert_not cm.valid?
    assert_includes cm.errors[:character], "must exist"
  end

  it "invalid without mastery" do
    cm = CharacterMastery.new(character: characters(:one))

    assert_not cm.valid?
    assert_includes cm.errors[:mastery], "must exist"
  end

  it "belongs_to character association" do
    cm =
      CharacterMastery.create!(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert_equal characters(:one), cm.character
  end

  it "belongs_to mastery association" do
    cm =
      CharacterMastery.create!(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert_equal masteries(:spear), cm.mastery
  end

  it "valid with nil mastery levels" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert cm.valid?
  end

  it "valid with mastery levels within range" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear),
        current_mastery_level: 0,
        target_mastery_level: Character::MAX_LEVEL
      )

    assert cm.valid?
  end

  it "invalid with current_mastery_level below 0" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear),
        current_mastery_level: -1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:current_mastery_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with current_mastery_level above MAX_LEVEL" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear),
        current_mastery_level: Character::MAX_LEVEL + 1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:current_mastery_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end

  it "invalid with target_mastery_level below 0" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear),
        target_mastery_level: -1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:target_mastery_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with target_mastery_level above MAX_LEVEL" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear),
        target_mastery_level: Character::MAX_LEVEL + 1
      )

    assert_not cm.valid?
    assert_includes cm.errors[:target_mastery_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end
end
