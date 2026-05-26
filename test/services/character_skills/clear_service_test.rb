require "test_helper"

class CharacterSkills::ClearServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @spear_mastery = create(:mastery, race: @chinese_race)
    @sword_sg =
      create(
        :skill_group,
        mastery: @blade_mastery,
        name: "Blade Skills",
        max_skill_level: 2
      )
    @spear_sg =
      create(:skill_group, mastery: @spear_mastery, name: "Spear Skills")
    @cold_sg = create(:skill_group, mastery: @blade_mastery)
    create(
      :skill_group_requirement,
      skill_group: @spear_sg,
      required_group: @sword_sg,
      required_skill_level: 1
    )
    @char = create(:character, race: @chinese_race)
    @cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sword_sg,
        current_skill_level: 2,
        target_skill_level: 2
      )
  end

  # --------- validations ----------------------------------------------------

  it "fails when CharacterSkill does not exist" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @cold_sg.id,
        field: :current
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  it "fails with an invalid field value" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :invalid
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("field") }
  end

  # --------- field: :current -----------------------------------------------

  it "zeros current_skill_level when field is :current" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: @sword_sg.id,
      field: :current
    )

    assert_equal 0, @cs.reload.current_skill_level
  end

  it "does not touch target_skill_level when field is :current" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: @sword_sg.id,
      field: :current
    )

    assert_equal 2, @cs.reload.target_skill_level
  end

  # --------- field: :target ------------------------------------------------

  it "zeros target_skill_level when field is :target" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: @sword_sg.id,
      field: :target
    )

    assert_equal 0, @cs.reload.target_skill_level
  end

  it "does not touch current_skill_level when field is :target" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: @sword_sg.id,
      field: :target
    )

    assert_equal 2, @cs.reload.current_skill_level
  end

  # --------- field: :both --------------------------------------------------

  it "zeros both levels when field is :both" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: @sword_sg.id,
      field: :both
    )

    @cs.reload
    assert_equal 0, @cs.current_skill_level
    assert_equal 0, @cs.target_skill_level
  end

  # --------- blocking dependents on :current -------------------------------

  it "fails when clearing current_skill_level would violate a dependent's requirement" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :current
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("blocked by") }
    assert result.errors.any? { |e| e.include?("Spear Skills") }
  end

  it "fails when clearing :both and current_skill_level has a blocking dependent" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :both
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("blocked by") }
  end

  it "does not check dependents when field is :target" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :target
      )

    assert result.success?
    assert_equal 0, @cs.reload.target_skill_level
  end

  it "does not block when dependent's current_skill_level is 0" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 0,
      target_skill_level: 1
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :current
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  it "does not block when no dependents exist for the character" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :current
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  # --------- return value --------------------------------------------------

  it "returns successful ServiceResult with the CharacterSkill" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: @sword_sg.id,
        field: :target
      )

    assert result.success?
    assert_instance_of CharacterSkill, result.data
    assert_empty result.errors
  end
end
