require "test_helper"

class CharacterSkills::ClearServiceTest < ActiveSupport::TestCase
  before do
    @char = characters(:one)
    # character_skills(:one) --- sword_mastery_skills, levels 1/1
    @cs = character_skills(:one)
    @cs.update!(current_skill_level: 2, target_skill_level: 2)
  end

  # --------- validations ----------------------------------------------------

  it "fails when CharacterSkill does not exist" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:cold_force_skills).id,
        field: :current
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  it "fails with an invalid field value" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        field: :invalid
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("field") }
  end

  # --------- field: :current -----------------------------------------------

  it "zeros current_skill_level when field is :current" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      field: :current
    )

    assert_equal 0, @cs.reload.current_skill_level
  end

  it "does not touch target_skill_level when field is :current" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      field: :current
    )

    assert_equal 2, @cs.reload.target_skill_level
  end

  # --------- field: :target ------------------------------------------------

  it "zeros target_skill_level when field is :target" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      field: :target
    )

    assert_equal 0, @cs.reload.target_skill_level
  end

  it "does not touch current_skill_level when field is :target" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      field: :target
    )

    assert_equal 2, @cs.reload.current_skill_level
  end

  # --------- field: :both --------------------------------------------------

  it "zeros both levels when field is :both" do
    CharacterSkills::ClearService.call(
      @char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      field: :both
    )

    @cs.reload
    assert_equal 0, @cs.current_skill_level
    assert_equal 0, @cs.target_skill_level
  end

  # --------- blocking dependents on :current -------------------------------

  it "fails when clearing current_skill_level would violate a dependent's requirement" do
    # spear requires sword at level 1; add spear with current_skill_level 1
    CharacterSkill.create!(
      character: @char,
      skill_group: skill_groups(:spear_mastery_skills),
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        field: :current
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("blocked by") }
    assert result.errors.any? { |e| e.include?("Spear Skills") }
  end

  it "fails when clearing :both and current_skill_level has a blocking dependent" do
    CharacterSkill.create!(
      character: @char,
      skill_group: skill_groups(:spear_mastery_skills),
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        field: :both
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("blocked by") }
  end

  it "does not check dependents when field is :target" do
    # even with a blocking dependent, :target clears without a check
    CharacterSkill.create!(
      character: @char,
      skill_group: skill_groups(:spear_mastery_skills),
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        field: :target
      )

    assert result.success?
    assert_equal 0, @cs.reload.target_skill_level
  end

  it "does not block when dependent's current_skill_level is 0" do
    CharacterSkill.create!(
      character: @char,
      skill_group: skill_groups(:spear_mastery_skills),
      current_skill_level: 0,
      target_skill_level: 1
    )

    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        field: :current
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  it "does not block when no dependents exist for the character" do
    result =
      CharacterSkills::ClearService.call(
        @char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        field: :target
      )

    assert result.success?
    assert_instance_of CharacterSkill, result.data
    assert_empty result.errors
  end
end
