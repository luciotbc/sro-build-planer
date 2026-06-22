require "test_helper"

class CharacterMasteries::MaxMasteryLevelServiceTest < ActiveSupport::TestCase
  before do
    @race = create(:race)
    @mastery = create(:mastery, race: @race)
    @char = create(:character, race: @race)
    @cm =
      CharacterMastery.create!(
        character: @char,
        mastery: @mastery,
        current_mastery_level: 30,
        target_mastery_level: 50
      )
  end

  it "sets current_mastery_level to cap when side is :current" do
    result =
      CharacterMasteries::MaxMasteryLevelService.call(
        @cm,
        side: :current,
        cap: 110
      )

    assert result.success?
    assert_equal 110, @cm.reload.current_mastery_level
  end

  it "sets target_mastery_level to cap when side is :target" do
    result =
      CharacterMasteries::MaxMasteryLevelService.call(
        @cm,
        side: :target,
        cap: 110
      )

    assert result.success?
    assert_equal 110, @cm.reload.target_mastery_level
  end

  it "does not update other side when setting current" do
    CharacterMasteries::MaxMasteryLevelService.call(
      @cm,
      side: :current,
      cap: 110
    )

    assert_equal 50, @cm.reload.target_mastery_level
  end

  it "does not update other side when setting target" do
    CharacterMasteries::MaxMasteryLevelService.call(
      @cm,
      side: :target,
      cap: 110
    )

    assert_equal 30, @cm.reload.current_mastery_level
  end

  it "returns successful ServiceResult with CharacterMastery" do
    result =
      CharacterMasteries::MaxMasteryLevelService.call(
        @cm,
        side: :current,
        cap: 110
      )

    assert result.success?
    assert_instance_of CharacterMastery, result.data
    assert_empty result.errors
  end

  it "fails with invalid side" do
    result =
      CharacterMasteries::MaxMasteryLevelService.call(
        @cm,
        side: :invalid,
        cap: 110
      )

    assert_not result.success?
    assert result.errors.any?
  end
end
