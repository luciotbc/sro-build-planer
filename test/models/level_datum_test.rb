require "test_helper"

class LevelDatumTest < ActiveSupport::TestCase
  it "valid with level" do
    assert LevelDatum.new(level: 200).valid?
  end

  it "invalid without level" do
    ld = LevelDatum.new

    assert_not ld.valid?
    assert_includes ld.errors[:level], "can't be blank"
  end

  it "invalid with duplicate level" do
    ld = LevelDatum.new(level: level_data(:one).level)

    assert_not ld.valid?
    assert_includes ld.errors[:level], "has already been taken"
  end
end
