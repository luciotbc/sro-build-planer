require "test_helper"

class Characters::PlanSummaryTest < ActiveSupport::TestCase
  before do
    @race = create(:race, :chinese)
    @user = create(:user)
    @character =
      create(
        :character,
        user: @user,
        race: @race,
        current_level: 30,
        target_level: 60
      )
    create(:level_datum, level: 30, sp_cumulative: 50_000)
    create(:level_datum, level: 60, sp_cumulative: 400_000)
  end

  it "exposes skill points from the cumulative SP table" do
    summary = Characters::PlanSummary.new(@character)

    assert_equal 50_000, summary.sp_current
    assert_equal 400_000, summary.sp_planned
  end

  it "sums mastery levels across the character masteries" do
    blade = create(:mastery, :blade, race: @race)
    cold = create(:mastery, :cold, race: @race)
    create(
      :character_mastery,
      character: @character,
      mastery: blade,
      current_mastery_level: 30,
      target_mastery_level: 60
    )
    create(
      :character_mastery,
      character: @character,
      mastery: cold,
      current_mastery_level: 10,
      target_mastery_level: 40
    )

    summary = Characters::PlanSummary.new(@character)

    assert_equal 40, summary.mastery_current
    assert_equal 100, summary.mastery_planned
  end

  it "exposes required levels from the character" do
    summary = Characters::PlanSummary.new(@character)

    assert_equal 30, summary.level_current
    assert_equal 60, summary.level_planned
  end

  it "returns zero skill points when no level data exists" do
    @character.update!(current_level: 5, target_level: 7)

    summary = Characters::PlanSummary.new(@character)

    assert_equal 0, summary.sp_current
    assert_equal 0, summary.sp_planned
  end
end
