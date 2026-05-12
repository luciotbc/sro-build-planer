require "test_helper"

class CharacterMasteryTest < ActiveSupport::TestCase
  test "valid with character and mastery" do
    cm =
      CharacterMastery.new(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert cm.valid?
  end

  test "invalid without character" do
    cm = CharacterMastery.new(mastery: masteries(:blade_sword))

    assert_not cm.valid?
    assert_includes cm.errors[:character], "must exist"
  end

  test "invalid without mastery" do
    cm = CharacterMastery.new(character: characters(:one))

    assert_not cm.valid?
    assert_includes cm.errors[:mastery], "must exist"
  end

  test "belongs_to character association" do
    cm =
      CharacterMastery.create!(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert_equal characters(:one), cm.character
  end

  test "belongs_to mastery association" do
    cm =
      CharacterMastery.create!(
        character: characters(:one),
        mastery: masteries(:spear)
      )

    assert_equal masteries(:spear), cm.mastery
  end
end
