require "test_helper"

class CharacterMasteries::ClearServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @spear_mastery = create(:mastery, race: @chinese_race)
    @sword_sg =
      create(:skill_group, mastery: @blade_mastery, max_skill_level: 2)
    @spear_sg = create(:skill_group, mastery: @spear_mastery)
    @char = create(:character, race: @chinese_race)
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
        current_skill_level: 2,
        target_skill_level: 2
      )
  end

  # --------- validation ----------------------------------------------------

  it "fails when CharacterMastery does not exist" do
    result =
      CharacterMasteries::ClearService.call(
        @char,
        mastery_id: @spear_mastery.id,
        field: :current
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  it "fails with an invalid field value" do
    result =
      CharacterMasteries::ClearService.call(
        @char,
        mastery_id: @blade_mastery.id,
        field: :invalid
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("field") }
  end

  # --------- field: :current -----------------------------------------------

  it "zeros current_mastery_level when field is :current" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :current
    )

    assert_equal 0, @cm.reload.current_mastery_level
  end

  it "zeros current_skill_level for all skills in the mastery when field is :current" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :current
    )

    assert_equal 0, @cs.reload.current_skill_level
  end

  it "does not touch target fields when field is :current" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :current
    )

    assert_equal 80, @cm.reload.target_mastery_level
    assert_equal 2, @cs.reload.target_skill_level
  end

  # --------- field: :target ------------------------------------------------

  it "zeros target_mastery_level when field is :target" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :target
    )

    assert_equal 0, @cm.reload.target_mastery_level
  end

  it "zeros target_skill_level for all skills in the mastery when field is :target" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :target
    )

    assert_equal 0, @cs.reload.target_skill_level
  end

  it "does not touch current fields when field is :target" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :target
    )

    assert_equal 60, @cm.reload.current_mastery_level
    assert_equal 2, @cs.reload.current_skill_level
  end

  # --------- field: :both --------------------------------------------------

  it "zeros both mastery levels when field is :both" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :both
    )

    @cm.reload
    assert_equal 0, @cm.current_mastery_level
    assert_equal 0, @cm.target_mastery_level
  end

  it "zeros both skill levels when field is :both" do
    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :both
    )

    @cs.reload
    assert_equal 0, @cs.current_skill_level
    assert_equal 0, @cs.target_skill_level
  end

  # --------- isolation -----------------------------------------------------

  it "does not affect skills of a different mastery" do
    spear_cm =
      CharacterMastery.create!(
        character: @char,
        mastery: @spear_mastery,
        current_mastery_level: 40
      )
    spear_cs =
      CharacterSkill.create!(
        character: @char,
        skill_group: @spear_sg,
        current_skill_level: 1
      )

    CharacterMasteries::ClearService.call(
      @char,
      mastery_id: @blade_mastery.id,
      field: :both
    )

    assert_equal 40, spear_cm.reload.current_mastery_level
    assert_equal 1, spear_cs.reload.current_skill_level
  end

  # --------- return value --------------------------------------------------

  it "returns successful ServiceResult with the CharacterMastery" do
    result =
      CharacterMasteries::ClearService.call(
        @char,
        mastery_id: @blade_mastery.id,
        field: :current
      )

    assert result.success?
    assert_instance_of CharacterMastery, result.data
    assert_empty result.errors
  end
end
