require "test_helper"

class CharacterMasteries::ClearServiceTest < ActiveSupport::TestCase
  setup do
    @char = characters(:one)
    @mastery = masteries(:blade_sword)
    @cm =
      CharacterMastery.create!(
        character: @char,
        mastery: @mastery,
        current_mastery_level: 60,
        target_mastery_level: 80
      )
    # character_skills(:one) → sword_mastery_skills (belongs to blade_sword)
    @cs = character_skills(:one)
    @cs.update!(current_skill_level: 2, target_skill_level: 2)
  end

  # ───────── validation ────────────────────────────────────────────────────

  test "fails when CharacterMastery does not exist" do
    result =
      CharacterMasteries::ClearService.call(
        @char,
        mastery_id: masteries(:spear).id,
        field: :current
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  test "fails with an invalid field value" do
    result =
      CharacterMasteries::ClearService.call(
        @char,
        mastery_id: @mastery.id,
        field: :invalid
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("field") }
  end

  # ───────── field: :current ───────────────────────────────────────────────

  test "zeros current_mastery_level when field is :current" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :current
    )

    assert_equal 0, @cm.reload.current_mastery_level
  end

  test "zeros current_skill_level for all skills in the mastery when field is :current" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :current
    )

    assert_equal 0, @cs.reload.current_skill_level
  end

  test "does not touch target fields when field is :current" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :current
    )

    assert_equal 80, @cm.reload.target_mastery_level
    assert_equal 2, @cs.reload.target_skill_level
  end

  # ───────── field: :target ────────────────────────────────────────────────

  test "zeros target_mastery_level when field is :target" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :target
    )

    assert_equal 0, @cm.reload.target_mastery_level
  end

  test "zeros target_skill_level for all skills in the mastery when field is :target" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :target
    )

    assert_equal 0, @cs.reload.target_skill_level
  end

  test "does not touch current fields when field is :target" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :target
    )

    assert_equal 60, @cm.reload.current_mastery_level
    assert_equal 2, @cs.reload.current_skill_level
  end

  # ───────── field: :both ──────────────────────────────────────────────────

  test "zeros both mastery levels when field is :both" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :both
    )

    @cm.reload
    assert_equal 0, @cm.current_mastery_level
    assert_equal 0, @cm.target_mastery_level
  end

  test "zeros both skill levels when field is :both" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :both
    )

    @cs.reload
    assert_equal 0, @cs.current_skill_level
    assert_equal 0, @cs.target_skill_level
  end

  # ───────── isolation ─────────────────────────────────────────────────────

  test "does not affect skills of a different mastery" do
    spear_cm =
      CharacterMastery.create!(
        character: @char,
        mastery: masteries(:spear),
        current_mastery_level: 40
      )
    spear_cs =
      CharacterSkill.create!(
        character: @char,
        skill_group: skill_groups(:spear_mastery_skills),
        current_skill_level: 1
      )

    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @mastery.id,
      field: :both
    )

    assert_equal 40, spear_cm.reload.current_mastery_level
    assert_equal 1, spear_cs.reload.current_skill_level
  end

  # ───────── return value ──────────────────────────────────────────────────

  test "returns successful ServiceResult with the CharacterMastery" do
    result =
      CharacterMasteries::ClearService.call(
        @char,
        mastery_id: @mastery.id,
        field: :current
      )

    assert result.success?
    assert_instance_of CharacterMastery, result.data
    assert_empty result.errors
  end
end
