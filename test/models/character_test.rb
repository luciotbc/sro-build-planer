require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  let(:race) { create(:race) }

  it "valid with name and race" do
    assert Character.new(name: "Test Character", race:).valid?
  end

  it "invalid without name" do
    character = Character.new(race:)

    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  it "invalid without race" do
    character = Character.new(name: "Test Character")

    assert_not character.valid?
    assert_includes character.errors[:race], "must exist"
  end

  it "belongs_to race association" do
    character = create(:character, race:)

    assert_equal race, character.race
  end

  it "has_many character_masteries" do
    assert_respond_to create(:character, race:), :character_masteries
  end

  it "has_many character_skills" do
    assert_respond_to create(:character, race:), :character_skills
  end

  it "MAX_LEVEL constant is 150" do
    assert_equal 150, Character::MAX_LEVEL
  end

  it "valid with current_level and target_level within range" do
    character =
      Character.new(
        name: "Test",
        race:,
        current_level: 1,
        target_level: Character::MAX_LEVEL
      )

    assert character.valid?
  end

  it "valid with nil current_level and target_level" do
    character = Character.new(name: "Test", race:)

    assert character.valid?
  end

  it "valid with current_level of 0" do
    character = Character.new(name: "Test", race:, current_level: 0)

    assert character.valid?
  end

  it "invalid with current_level below 0" do
    character = Character.new(name: "Test", race:, current_level: -1)

    assert_not character.valid?
    assert_includes character.errors[:current_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with current_level above MAX_LEVEL" do
    character =
      Character.new(
        name: "Test",
        race:,
        current_level: Character::MAX_LEVEL + 1
      )

    assert_not character.valid?
    assert_includes character.errors[:current_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end

  it "valid with target_level of 0" do
    character = Character.new(name: "Test", race:, target_level: 0)

    assert character.valid?
  end

  it "invalid with target_level below 0" do
    character = Character.new(name: "Test", race:, target_level: -1)

    assert_not character.valid?
    assert_includes character.errors[:target_level],
                    "must be greater than or equal to 0"
  end

  it "invalid with target_level above MAX_LEVEL" do
    character =
      Character.new(name: "Test", race:, target_level: Character::MAX_LEVEL + 1)

    assert_not character.valid?
    assert_includes character.errors[:target_level],
                    "must be less than or equal to #{Character::MAX_LEVEL}"
  end

  it "invalid with non-integer current_level" do
    character = Character.new(name: "Test", race:, current_level: 1.5)

    assert_not character.valid?
    assert_includes character.errors[:current_level], "must be an integer"
  end

  it "invalid with blank name" do
    character = Character.new(name: "", race:)

    assert_not character.valid?
    assert_includes character.errors[:name], "can't be blank"
  end

  it "invalid with nonexistent race_id" do
    character = Character.new(name: "Test", race_id: 0)

    assert_not character.valid?
    assert_includes character.errors[:race], "must exist"
  end

  it "valid without a user (imported or legacy data)" do
    assert Character.new(name: "Test", race:).valid?
  end

  it "belongs_to user association" do
    user = create(:user)
    character = create(:character, race:, user:)

    assert_equal user, character.user
    assert_includes user.characters, character
  end

  it "is destroyed when its user is destroyed" do
    user = create(:user)
    character = create(:character, race:, user:)

    user.destroy!

    assert_not Character.exists?(character.id)
  end

  it "target_level can be lower than current_level without error" do
    character =
      Character.new(name: "Test", race:, current_level: 80, target_level: 30)

    assert character.valid?
  end
end
