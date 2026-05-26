require "test_helper"

class CharacterMasteries::AddServiceTest < ActiveSupport::TestCase
  # --------- validation order -----------------------------------------------

  it "fails with non-existent mastery_id" do
    result =
      CharacterMasteries::AddService.call(characters(:one), mastery_id: 0)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Mastery must exist") }
  end

  it "fails when mastery race differs from character race" do
    result =
      CharacterMasteries::AddService.call(
        characters(:one),
        mastery_id: masteries(:warrior).id
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("race") }
  end

  it "fails when mastery already added to character" do
    char = characters(:one)
    CharacterMastery.create!(character: char, mastery: masteries(:blade_sword))

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("already been added") }
  end

  # --------- happy path ----------------------------------------------------

  it "creates CharacterMastery with default levels" do
    result =
      CharacterMasteries::AddService.call(
        characters(:one),
        mastery_id: masteries(:blade_sword).id
      )

    assert result.success?
    assert_instance_of CharacterMastery, result.data
    assert_equal 0, result.data.current_mastery_level
    assert_equal 0, result.data.target_mastery_level
  end

  it "creates CharacterMastery with provided levels" do
    result =
      CharacterMasteries::AddService.call(
        characters(:one),
        mastery_id: masteries(:blade_sword).id,
        current_mastery_level: 20,
        target_mastery_level: 40
      )

    assert result.success?
    assert_equal 20, result.data.current_mastery_level
    assert_equal 40, result.data.target_mastery_level
  end

  it "persists the CharacterMastery" do
    assert_difference "CharacterMastery.count", 1 do
      CharacterMasteries::AddService.call(
        characters(:one),
        mastery_id: masteries(:blade_sword).id
      )
    end
  end

  # --------- auto-update character levels ----------------------------------

  it "raises character current_level when mastery level exceeds it" do
    char = characters(:one)
    char.update!(current_level: 10)

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id,
        current_mastery_level: 30
      )

    assert result.success?
    assert_equal 30, char.reload.current_level
    assert result.warnings.any? { |w|
             w.include?("current_level") && w.include?("30")
           }
  end

  it "raises character target_level when mastery level exceeds it" do
    char = characters(:one)
    char.update!(target_level: 10)

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id,
        target_mastery_level: 50
      )

    assert result.success?
    assert_equal 50, char.reload.target_level
    assert result.warnings.any? { |w|
             w.include?("target_level") && w.include?("50")
           }
  end

  it "emits two warnings when both levels are raised" do
    char = characters(:one)
    char.update!(current_level: 5, target_level: 5)

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id,
        current_mastery_level: 20,
        target_mastery_level: 40
      )

    assert result.success?
    assert_equal 2, result.warnings.size
    assert_equal 20, char.reload.current_level
    assert_equal 40, char.reload.target_level
  end

  it "does not update character level when mastery level is equal" do
    char = characters(:one)
    char.update!(current_level: 20)

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id,
        current_mastery_level: 20
      )

    assert result.success?
    assert_empty result.warnings
    assert_equal 20, char.reload.current_level
  end

  it "does not update character level when mastery level is lower" do
    char = characters(:one)
    char.update!(current_level: 50)

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id,
        current_mastery_level: 30
      )

    assert result.success?
    assert_empty result.warnings
    assert_equal 50, char.reload.current_level
  end

  it "returns warnings in ServiceResult" do
    char = characters(:one)
    char.update!(current_level: 0)

    result =
      CharacterMasteries::AddService.call(
        char,
        mastery_id: masteries(:blade_sword).id,
        current_mastery_level: 10
      )

    assert_instance_of Array, result.warnings
    assert_instance_of Array, result.errors
    assert_empty result.errors
  end
end
