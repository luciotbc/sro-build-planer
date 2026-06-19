require "test_helper"

class CharacterMasteries::UpdateServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @spear_mastery = create(:mastery, race: @chinese_race)
    @sword_sg =
      create(:skill_group, mastery: @blade_mastery, max_skill_level: 2)
    @spear_sg = create(:skill_group, mastery: @spear_mastery)
    create(:skill, skill_group: @sword_sg, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sword_sg, skill_level: 2, mastery_level_req: 5)
    @char =
      create(
        :character,
        race: @chinese_race,
        current_level: 80,
        target_level: 100
      )
    @cm =
      CharacterMastery.create!(
        character: @char,
        mastery: @blade_mastery,
        current_mastery_level: 60,
        target_mastery_level: 80
      )
    @cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sword_sg,
        current_skill_level: 1,
        target_skill_level: 1
      )
  end

  # --------- existence validation -------------------------------------------

  it "fails when CharacterMastery does not exist for the character" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @spear_mastery.id,
        current_mastery_level: 30
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  # --------- happy-path updates ---------------------------------------------

  it "updates current_mastery_level" do
    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @blade_mastery.id,
      current_mastery_level: 70
    )

    assert_equal 70, @cm.reload.current_mastery_level
  end

  it "updates target_mastery_level" do
    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @blade_mastery.id,
      target_mastery_level: 90
    )

    assert_equal 90, @cm.reload.target_mastery_level
  end

  it "updates both levels in one call" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 55,
        target_mastery_level: 75
      )

    assert result.success?
    assert_equal 55, @cm.reload.current_mastery_level
    assert_equal 75, @cm.reload.target_mastery_level
  end

  it "does not change fields not included in params" do
    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @blade_mastery.id,
      current_mastery_level: 50
    )

    assert_equal 80, @cm.reload.target_mastery_level
  end

  it "returns ServiceResult with success and data" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 55
      )

    assert result.success?
    assert_instance_of CharacterMastery, result.data
  end

  # --------- auto-update character level -----------------------------------

  it "auto-updates character current_level when mastery exceeds it" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 90
      )

    assert result.success?
    assert_equal 90, @char.reload.current_level
    assert result.warnings.any? { |w|
             w.include?("current_level") && w.include?("90")
           }
  end

  it "auto-updates character target_level when mastery exceeds it" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        target_mastery_level: 110
      )

    assert result.success?
    assert_equal 110, @char.reload.target_level
    assert result.warnings.any? { |w|
             w.include?("target_level") && w.include?("110")
           }
  end

  it "recomputes character level to new mastery level even when it decreases" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 50
      )

    assert result.success?
    # per spec 01 R1: current_level = MAX(mastery levels) = 50 after update
    assert_equal 50, @char.reload.current_level
    assert_empty result.warnings
  end

  it "does not change current_level when only target_mastery_level is updated" do
    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        target_mastery_level: 75
      )

    assert result.success?
    # current_level = MAX(current_mastery_levels) = 60 (set by callback during before)
    assert_equal 60, @char.reload.current_level
  end

  # --------- current_skill_level cascade -----------------------------------

  it "cascades current_skill_level when mastery drops below skill requirement" do
    @cs.update!(current_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 3
      )

    assert result.success?
    assert_equal 1, @cs.reload.current_skill_level
    assert result.warnings.any? { |w| w.include?("current_skill_level") }
  end

  it "sets current_skill_level to 0 when no skill fits the new mastery" do
    @cs.update!(current_skill_level: 1)

    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @blade_mastery.id,
      current_mastery_level: 0
    )

    assert_equal 0, @cs.reload.current_skill_level
  end

  it "does not cascade current_skill_level when current_skill is nil" do
    @cs.update!(current_skill_level: 0)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
    assert_empty result.warnings
  end

  it "does not cascade skills when mastery level is not decreasing" do
    @cs.update!(current_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 70
      )

    assert result.success?
    assert_equal 2, @cs.reload.current_skill_level
    # no skill cascade warnings; a character level warning may appear since level rose above 60
    assert result.warnings.none? { |w| w.include?("current_skill_level") }
  end

  it "does not cascade skills that belong to a different mastery" do
    spear_cs =
      CharacterSkill.create!(
        character: @char,
        skill_group: @spear_sg,
        current_skill_level: 1
      )

    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @blade_mastery.id,
      current_mastery_level: 0
    )

    assert_equal 1, spear_cs.reload.current_skill_level
  end

  it "does not cascade when current_mastery_level param is absent" do
    @cs.update!(current_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        target_mastery_level: 30
      )

    assert result.success?
    assert_equal 2, @cs.reload.current_skill_level
  end

  # --------- target_skill_level cascade ------------------------------------

  it "cascades target_skill_level when target mastery drops below skill requirement" do
    @cs.update!(target_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        target_mastery_level: 3
      )

    assert result.success?
    assert_equal 1, @cs.reload.target_skill_level
    assert result.warnings.any? { |w| w.include?("target_skill_level") }
  end

  it "sets target_skill_level to 0 when no skill fits the new target mastery" do
    @cs.update!(target_skill_level: 1)

    CharacterMasteries::UpdateService.call(
      @char,
      mastery_id: @blade_mastery.id,
      target_mastery_level: 0
    )

    assert_equal 0, @cs.reload.target_skill_level
  end

  # --------- both cascades in one call -------------------------------------

  it "cascades both current and target skill levels in one call" do
    @cs.update!(current_skill_level: 2, target_skill_level: 2)

    result =
      CharacterMasteries::UpdateService.call(
        @char,
        mastery_id: @blade_mastery.id,
        current_mastery_level: 3,
        target_mastery_level: 3
      )

    assert result.success?
    assert_equal 1, @cs.reload.current_skill_level
    assert_equal 1, @cs.reload.target_skill_level
    assert_equal 2, result.warnings.size
  end
end
