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
end
