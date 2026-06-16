require "test_helper"

class RaceTest < ActiveSupport::TestCase
  let(:race) { create(:race) }

  it "valid with external_id and name" do
    r = Race.new(external_id: 3, name: "Orc")

    assert r.valid?
  end

  it "invalid without external_id" do
    r = Race.new(name: "Orc")

    assert_not r.valid?
    assert_includes r.errors[:external_id], "can't be blank"
  end

  it "invalid with duplicate external_id" do
    r = Race.new(external_id: race.external_id, name: "New Race")

    assert_not r.valid?
    assert_includes r.errors[:external_id], "has already been taken"
  end

  it "invalid without name" do
    r = Race.new(external_id: 4)

    assert_not r.valid?
    assert_includes r.errors[:name], "can't be blank"
  end

  it "database rejects null name" do
    r = Race.new(external_id: 4, name: nil)

    assert_raises(ActiveRecord::NotNullViolation) { r.save!(validate: false) }
  end

  it "has_many masteries" do
    assert_respond_to race, :masteries
  end

  it "has_many characters" do
    assert_respond_to race, :characters
  end
end
