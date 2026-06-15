require "test_helper"

class Characters::SkillWindowTest < ActiveSupport::TestCase
  before do
    @race = create(:race, :chinese)
    @character = create(:character, race: @race)
  end

  it "falls back to the first mastery type when group param is not a valid type" do
    create(:mastery, :blade, race: @race)

    window = Characters::SkillWindow.new(@character, group: "NonExistentType")

    assert_equal "Weapon", window.active_type
  end

  it "ignores a mastery_id that belongs to a different race" do
    other_race = create(:race, :european)
    own_mastery = create(:mastery, :blade, race: @race)
    foreign_mastery = create(:mastery, :warrior, race: other_race)

    window =
      Characters::SkillWindow.new(@character, mastery_id: foreign_mastery.id)

    assert_equal own_mastery, window.mastery
  end

  it "returns nil mastery and empty series when the race has no masteries" do
    window = Characters::SkillWindow.new(@character)

    assert_nil window.mastery
    assert_equal [], window.series
  end
end
