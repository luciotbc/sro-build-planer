require "test_helper"

class RaceTest < ActiveSupport::TestCase
  test "valid with external_id and name" do
    race = Race.new(external_id: 3, name: "Orc")

    assert race.valid?
  end

  test "invalid without external_id" do
    race = Race.new(name: "Orc")

    assert_not race.valid?
    assert_includes race.errors[:external_id], "can't be blank"
  end

  test "invalid with duplicate external_id" do
    existing_race = races(:chinese)
    race = Race.new(external_id: existing_race.external_id, name: "New Race")

    assert_not race.valid?
    assert_includes race.errors[:external_id], "has already been taken"
  end

  test "invalid without name" do
    race = Race.new(external_id: 4)

    assert_not race.valid?
    assert_includes race.errors[:name], "can't be blank"
  end

  test "database rejects null name" do
    race = Race.new(external_id: 4, name: nil)

    assert_raises(ActiveRecord::NotNullViolation) do
      race.save!(validate: false)
    end
  end

  test "has_many masteries" do
    assert_respond_to races(:chinese), :masteries
  end

  test "has_many characters" do
    assert_respond_to races(:chinese), :characters
  end
end
