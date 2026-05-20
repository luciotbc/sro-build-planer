require "test_helper"

class CharacterMasteries::UpdateServiceTest < ActiveSupport::TestCase
  setup do
    @char = characters(:one)
    @char.update!(current_level: 80, target_level: 100)
    @mastery = masteries(:blade_sword)
    @cm =
      CharacterMastery.create!(
        character: @char,
        mastery: @mastery,
        current_mastery_level: 60,
        target_mastery_level: 80
      )
    # fixture character_skills(:one) → sword_mastery_skills, levels 1/1
    @cs = character_skills(:one)
  end

  # ───────── existence validation ───────────────────────────────────────────

  test "fails when CharacterMastery does not exist for the character" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: masteries(:spear).id,
        current_mastery_level: 30
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  # ───────── happy-path updates ─────────────────────────────────────────────

  test "updates current_mastery_level" do
    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @mastery.id,
      current_mastery_level: 70
    )

    assert_equal 70, @cm.reload.current_mastery_level
  end

  test "updates target_mastery_level" do
    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @mastery.id,
      target_mastery_level: 90
    )

    assert_equal 90, @cm.reload.target_mastery_level
  end

  test "updates both levels in one call" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 55,
        target_mastery_level: 75
      )

    assert result.success?
    assert_equal 55, @cm.reload.current_mastery_level
    assert_equal 75, @cm.reload.target_mastery_level
  end

  test "does not change fields not included in params" do
    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @mastery.id,
      current_mastery_level: 50
    )

    assert_equal 80, @cm.reload.target_mastery_level
  end

  test "returns ServiceResult with success and data" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 55
      )

    assert result.success?
    assert_instance_of CharacterMastery, result.data
  end

  # ───────── auto-update character level ───────────────────────────────────

  test "auto-updates character current_level when mastery exceeds it" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 90
      )

    assert result.success?
    assert_equal 90, @char.reload.current_level
    assert result.warnings.any? { |w|
             w.include?("current_level") && w.include?("90")
           }
  end

  test "auto-updates character target_level when mastery exceeds it" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        target_mastery_level: 110
      )

    assert result.success?
    assert_equal 110, @char.reload.target_level
    assert result.warnings.any? { |w|
             w.include?("target_level") && w.include?("110")
           }
  end

  test "does not auto-update character level when mastery level is within range" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 50
      )

    assert result.success?
    assert_equal 80, @char.reload.current_level
    assert_empty result.warnings
  end

  test "does not auto-update when level param is not provided" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        target_mastery_level: 75
      )

    assert result.success?
    assert_equal 80, @char.reload.current_level
  end

  # ───────── current_skill_level cascade ───────────────────────────────────

  test "cascades current_skill_level when mastery drops below skill requirement" do
    @cs.update!(current_skill_level: 2) # blade_active_skill, mastery_level_req 5

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 3
      )

    assert result.success?
    # blade_passive_skill (level 1, mastery_req 1) is the smallest that fits
    assert_equal 1, @cs.reload.current_skill_level
    assert result.warnings.any? { |w| w.include?("current_skill_level") }
  end

  test "sets current_skill_level to 0 when no skill fits the new mastery" do
    @cs.update!(current_skill_level: 1) # blade_passive_skill, mastery_level_req 1

    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @mastery.id,
      current_mastery_level: 0
    )

    assert_equal 0, @cs.reload.current_skill_level
  end

  test "does not cascade current_skill_level when current_skill is nil" do
    @cs.update!(current_skill_level: 0)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
    assert_empty result.warnings
  end

  test "does not cascade when mastery level is not decreasing" do
    @cs.update!(current_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 70
      )

    assert result.success?
    assert_equal 2, @cs.reload.current_skill_level
    assert_empty result.warnings
  end

  test "does not cascade skills that belong to a different mastery" do
    spear_cs =
      CharacterSkill.create!(
        character: @char,
        skill_group: skill_groups(:spear_mastery_skills),
        current_skill_level: 1
      )

    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @mastery.id,
      current_mastery_level: 0
    )

    assert_equal 1, spear_cs.reload.current_skill_level
  end

  test "does not cascade when current_mastery_level param is absent" do
    @cs.update!(current_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        target_mastery_level: 30
      )

    assert result.success?
    assert_equal 2, @cs.reload.current_skill_level
  end

  # ───────── target_skill_level cascade ────────────────────────────────────

  test "cascades target_skill_level when target mastery drops below skill requirement" do
    @cs.update!(target_skill_level: 2) # blade_active_skill, mastery_level_req 5

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        target_mastery_level: 3
      )

    assert result.success?
    assert_equal 1, @cs.reload.target_skill_level
    assert result.warnings.any? { |w| w.include?("target_skill_level") }
  end

  test "sets target_skill_level to 0 when no skill fits the new target mastery" do
    @cs.update!(target_skill_level: 1)

    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @mastery.id,
      target_mastery_level: 0
    )

    assert_equal 0, @cs.reload.target_skill_level
  end

  # ───────── both cascades in one call ─────────────────────────────────────

  test "cascades both current and target skill levels in one call" do
    @cs.update!(current_skill_level: 2, target_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @mastery.id,
        current_mastery_level: 3,
        target_mastery_level: 3
      )

    assert result.success?
    assert_equal 1, @cs.reload.current_skill_level
    assert_equal 1, @cs.reload.target_skill_level
    assert_equal 2, result.warnings.size
  end
end
