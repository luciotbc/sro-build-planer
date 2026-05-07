require "test_helper"

class MasteryTest < ActiveSupport::TestCase
  test "valid with external_id, name, mastery_type, and race" do
    race = races(:chinese)
    mastery = Mastery.new(external_id: 999, name: "Test Mastery", mastery_type: "Weapon", race: race)

    assert mastery.valid?
  end

  test "invalid without external_id" do
    race = races(:chinese)
    mastery = Mastery.new(name: "Test Mastery", mastery_type: "Weapon", race: race)

    assert_not mastery.valid?
    assert_includes mastery.errors[:external_id], "can't be blank"
  end

  test "invalid with duplicate external_id" do
    existing_mastery = masteries(:blade_sword)
    race = races(:chinese)
    mastery = Mastery.new(external_id: existing_mastery.external_id, name: "New Mastery", mastery_type: "Weapon", race: race)

    assert_not mastery.valid?
    assert_includes mastery.errors[:external_id], "has already been taken"
  end

  test "invalid without name" do
    race = races(:chinese)
    mastery = Mastery.new(external_id: 1000, mastery_type: "Weapon", race: race)

    assert_not mastery.valid?
    assert_includes mastery.errors[:name], "can't be blank"
  end

  test "invalid without mastery_type" do
    race = races(:chinese)
    mastery = Mastery.new(external_id: 1001, name: "Test Mastery", race: race)

    assert_not mastery.valid?
    assert_includes mastery.errors[:mastery_type], "can't be blank"
  end

  test "invalid with invalid mastery_type" do
    race = races(:chinese)
    mastery = Mastery.new(external_id: 1002, name: "Test Mastery", mastery_type: "Invalid", race: race)

    assert_not mastery.valid?
    assert_includes mastery.errors[:mastery_type], "is not included in the list"
  end

  test "invalid without race" do
    mastery = Mastery.new(external_id: 1003, name: "Test Mastery", mastery_type: "Weapon")

    assert_not mastery.valid?
    assert_includes mastery.errors[:race], "must exist"
  end

  test "belongs_to race association" do
    mastery = masteries(:blade_sword)

    assert_equal races(:chinese), mastery.race
  end

  test "database rejects null name" do
    race = races(:chinese)
    mastery = Mastery.new(external_id: 1004, name: nil, mastery_type: "Weapon", race: race)

    assert_raises(ActiveRecord::NotNullViolation) do
      mastery.save!(validate: false)
    end
  end

  test "database rejects null mastery_type" do
    race = races(:chinese)
    mastery = Mastery.new(external_id: 1005, name: "Test Mastery", mastery_type: nil, race: race)

    assert_raises(ActiveRecord::NotNullViolation) do
      mastery.save!(validate: false)
    end
  end

  test "database rejects null race_id" do
    mastery = Mastery.new(external_id: 1006, name: "Test Mastery", mastery_type: "Weapon", race_id: nil)

    assert_raises(ActiveRecord::NotNullViolation) do
      mastery.save!(validate: false)
    end
  end
end
