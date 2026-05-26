require "test_helper"

class MasteryTest < ActiveSupport::TestCase
  let(:race) { create(:race) }
  let(:mastery) { create(:mastery, race:) }

  it "valid with external_id, name, mastery_type, and race" do
    m =
      Mastery.new(
        external_id: 999,
        name: "Test Mastery",
        mastery_type: "Weapon",
        race:
      )

    assert m.valid?
  end

  it "invalid without external_id" do
    m = Mastery.new(name: "Test Mastery", mastery_type: "Weapon", race:)

    assert_not m.valid?
    assert_includes m.errors[:external_id], "can't be blank"
  end

  it "invalid with duplicate external_id" do
    m =
      Mastery.new(
        external_id: mastery.external_id,
        name: "New Mastery",
        mastery_type: "Weapon",
        race:
      )

    assert_not m.valid?
    assert_includes m.errors[:external_id], "has already been taken"
  end

  it "invalid without name" do
    m = Mastery.new(external_id: 1000, mastery_type: "Weapon", race:)

    assert_not m.valid?
    assert_includes m.errors[:name], "can't be blank"
  end

  it "invalid without mastery_type" do
    m = Mastery.new(external_id: 1001, name: "Test Mastery", race:)

    assert_not m.valid?
    assert_includes m.errors[:mastery_type], "can't be blank"
  end

  it "invalid with invalid mastery_type" do
    m =
      Mastery.new(
        external_id: 1002,
        name: "Test Mastery",
        mastery_type: "Invalid",
        race:
      )

    assert_not m.valid?
    assert_includes m.errors[:mastery_type], "is not included in the list"
  end

  it "invalid without race" do
    m =
      Mastery.new(
        external_id: 1003,
        name: "Test Mastery",
        mastery_type: "Weapon"
      )

    assert_not m.valid?
    assert_includes m.errors[:race], "must exist"
  end

  it "belongs_to race association" do
    assert_equal race, mastery.race
  end

  it "database rejects null name" do
    m = Mastery.new(external_id: 1004, name: nil, mastery_type: "Weapon", race:)

    assert_raises(ActiveRecord::NotNullViolation) { m.save!(validate: false) }
  end

  it "database rejects null mastery_type" do
    m =
      Mastery.new(
        external_id: 1005,
        name: "Test Mastery",
        mastery_type: nil,
        race:
      )

    assert_raises(ActiveRecord::NotNullViolation) { m.save!(validate: false) }
  end

  it "database rejects null race_id" do
    m =
      Mastery.new(
        external_id: 1006,
        name: "Test Mastery",
        mastery_type: "Weapon",
        race_id: nil
      )

    assert_raises(ActiveRecord::NotNullViolation) { m.save!(validate: false) }
  end
end
