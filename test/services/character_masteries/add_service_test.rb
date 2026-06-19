require "test_helper"

class CharacterMasteries::AddServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @european_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @warrior_mastery = create(:mastery, race: @european_race)
    @char = create(:character, race: @chinese_race)
  end

  # --------- validation order -----------------------------------------------

  it "fails with non-existent mastery_id" do
    result = CharacterMasteries::AddService.call(@char, mastery_id: 0)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Mastery must exist") }
  end

  it "fails when mastery race differs from character race" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @warrior_mastery.id
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("race") }
  end

  it "fails when mastery already added to character" do
    CharacterMastery.create!(character: @char, mastery: @blade_mastery)

    result =
      CharacterMasteries::AddService.call(@char, mastery_id: @blade_mastery.id)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("already been added") }
  end

  # --------- happy path ----------------------------------------------------

  it "creates CharacterMastery with default levels" do
    result =
      CharacterMasteries::AddService.call(@char, mastery_id: @blade_mastery.id)

    assert result.success?
    assert_instance_of CharacterMastery, result.data
    assert_equal 0, result.data.current_mastery_level
    assert_equal 0, result.data.target_mastery_level
  end

  it "creates CharacterMastery with provided levels" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 20,
        target_mastery_level: 40
      )

    assert result.success?
    assert_equal 20, result.data.current_mastery_level
    assert_equal 40, result.data.target_mastery_level
  end

  it "persists the CharacterMastery" do
    assert_difference "CharacterMastery.count", 1 do
      CharacterMasteries::AddService.call(@char, mastery_id: @blade_mastery.id)
    end
  end

  # --------- auto-update character levels ----------------------------------

  it "raises character current_level when mastery level is added (callback)" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 30
      )

    assert result.success?
    assert_equal 30, @char.reload.current_level
  end

  it "raises character target_level when mastery level is added (callback)" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        target_mastery_level: 50
      )

    assert result.success?
    assert_equal 50, @char.reload.target_level
  end

  it "emits no character level warnings (level maintained by callback)" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 20,
        target_mastery_level: 40
      )

    assert result.success?
    assert_empty result.warnings
    assert_equal 20, @char.reload.current_level
    assert_equal 40, @char.reload.target_level
  end

  it "character level reflects mastery level even when equal" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 20
      )

    assert result.success?
    assert_empty result.warnings
    assert_equal 20, @char.reload.current_level
  end

  it "recomputes character level to mastery level (per spec 01 R1: MAX of masteries)" do
    @char.update!(current_level: 50)

    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 30
      )

    assert result.success?
    assert_empty result.warnings
    assert_equal 30, @char.reload.current_level
  end

  it "returns warnings and errors arrays in ServiceResult" do
    result =
      CharacterMasteries::AddService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 10
      )

    assert_instance_of Array, result.warnings
    assert_instance_of Array, result.errors
    assert_empty result.errors
  end
end
