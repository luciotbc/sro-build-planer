require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  test "valid with name and race" do
    assert Character.new(name: "Test Character", race: races(:chinese)).valid?
  end

  test "invalid without name" do
    character = Character.new(race: races(:chinese))

    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  test "invalid without race" do
    character = Character.new(name: "Test Character")

    assert_not character.valid?
    assert_includes character.errors[:race], "must exist"
  end

  test "belongs_to race association" do
    assert_equal races(:chinese), characters(:one).race
  end

  test "has_many character_masteries" do
    assert_respond_to characters(:one), :character_masteries
  end

  test "has_many character_skills" do
    assert_respond_to characters(:one), :character_skills
  end

  test "MAX_LEVEL constant is 150" do
    assert_equal 150, Character::MAX_LEVEL
  end

  test "valid with current_level and target_level within range" do
    character =
      Character.new(
        name: "Test",
        race: races(:chinese),
        current_level: 1,
        target_level: Character::MAX_LEVEL
      )

    assert character.valid?
  end

  test "valid with nil current_level and target_level" do
    character = Character.new(name: "Test", race: races(:chinese))

    assert character.valid?
  end

  test "valid with current_level of 0" do
    character =
      Character.new(name: "Test", race: races(:chinese), current_level: 0)

    assert character.valid?
  end

  test "invalid with current_level below 0" do
    character =
      Character.new(name: "Test", race: races(:chinese), current_level: -1)

    assert_not character.valid?
    assert_includes character.errors[:current_level],
                    "must be greater than or equal to 0"
  end

  test "invalid with current_level above MAX_LEVEL" do
    character =
      Character.new(
        name: "Test",
        race: races(:chinese),
        current_level: Character::MAX_LEVEL + 1
      )

    assert_not character.valid?
    assert_includes character.errors[:current_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end

  test "valid with target_level of 0" do
    character =
      Character.new(name: "Test", race: races(:chinese), target_level: 0)

    assert character.valid?
  end

  test "invalid with target_level below 0" do
    character =
      Character.new(name: "Test", race: races(:chinese), target_level: -1)

    assert_not character.valid?
    assert_includes character.errors[:target_level],
                    "must be greater than or equal to 0"
  end

  test "invalid with target_level above MAX_LEVEL" do
    character =
      Character.new(
        name: "Test",
        race: races(:chinese),
        target_level: Character::MAX_LEVEL + 1
      )

    assert_not character.valid?
    assert_includes character.errors[:target_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end

  test "invalid with non-integer current_level" do
    character =
      Character.new(name: "Test", race: races(:chinese), current_level: 1.5)

    assert_not character.valid?
    assert_includes character.errors[:current_level], "must be an integer"
  end
end
