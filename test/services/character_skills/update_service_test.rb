require "test_helper"

class CharacterSkills::UpdateServiceTest < ActiveSupport::TestCase
  # --------- helpers --------------------------------------------------------

  def setup
    @char = characters(:one)
    # characters(:one) already has character_skills(:one) --- sword_mastery_skills at 1/1
    @cs = character_skills(:one)
    @sg = skill_groups(:sword_mastery_skills)
    CharacterMastery.create!(
      character: @char,
      mastery: masteries(:blade_sword),
      current_mastery_level: 1,
      target_mastery_level: 1
    )
  end

  def fresh_char
    Character.create!(
      name: "Fresh",
      race: races(:chinese),
      current_level: 0,
      target_level: 0
    )
  end

  # --------- existence validation -------------------------------------------

  it "fails when CharacterSkill does not exist for the character" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: skill_groups(:cold_force_skills).id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  # --------- immutable fields -----------------------------------------------

  it "fails when character_id is provided" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        character_id: characters(:two).id
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("character_id cannot be changed")
           }
  end

  it "still finds the CharacterSkill when skill_group_id matches the existing one" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 1
      )

    assert result.success?
    assert_equal @cs, result.data
  end

  # --------- level range validations ---------------------------------------

  it "fails when current_skill_level is negative" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: -1
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("current_skill_level") && e.include?(">= 0")
           }
  end

  it "fails when current_skill_level exceeds max_skill_level" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 3
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("current_skill_level") && e.include?("<= 2")
           }
  end

  it "fails when target_skill_level is negative" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        target_skill_level: -1
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("target_skill_level") && e.include?(">= 0")
           }
  end

  it "fails when target_skill_level exceeds max_skill_level" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        target_skill_level: 3
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("target_skill_level") && e.include?("<= 2")
           }
  end

  # --------- happy path -----------------------------------------------------

  it "updates current_skill_level" do
    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sg.id,
      current_skill_level: 2
    )

    assert_equal 2, @cs.reload.current_skill_level
  end

  it "updates target_skill_level" do
    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sg.id,
      target_skill_level: 2
    )

    assert_equal 2, @cs.reload.target_skill_level
  end

  it "updates both levels in one call" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 2,
        target_skill_level: 2
      )

    assert result.success?
    @cs.reload
    assert_equal 2, @cs.current_skill_level
    assert_equal 2, @cs.target_skill_level
  end

  it "does not change fields not provided in params" do
    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sg.id,
      current_skill_level: 2
    )

    assert_equal 1, @cs.reload.target_skill_level
  end

  it "returns successful ServiceResult with CharacterSkill" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 2
      )

    assert result.success?
    assert_instance_of CharacterSkill, result.data
  end

  it "accepts current_skill_level of 0" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  it "accepts target_skill_level of 0" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        target_skill_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.target_skill_level
  end

  it "returns not found when skill_group_id does not match any CharacterSkill for the character" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: skill_groups(:cold_force_skills).id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  # --------- blocking dependents on decrease --------------------------------

  it "fails when decreasing current_skill_level below a dependent's requirement" do
    # cold_force_skills requires sword at level 3; char has sword at 1
    # first add spear (requires sword at 1) to make it a dependent
    CharacterSkill.create!(
      character: @char,
      skill_group: skill_groups(:spear_mastery_skills),
      current_skill_level: 1,
      target_skill_level: 1
    )

    # sword is at level 1, spear requires sword at 1 --- cannot drop sword to 0
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 0
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("blocked by") }
    assert result.errors.any? { |e| e.include?("Spear Skills") }
  end

  it "does not block when dependent's current_skill_level is 0" do
    CharacterSkill.create!(
      character: @char,
      skill_group: skill_groups(:spear_mastery_skills),
      current_skill_level: 0,
      target_skill_level: 1
    )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 0
      )

    assert result.success?
  end

  it "does not block when no dependents exist for the character" do
    # char has no spear or cold skill --- free to decrease sword
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  # --------- prerequisite resolution on increase ---------------------------

  it "does not resolve prerequisites when current_skill_level is not increasing" do
    # sword at 1, only update target --- no prereq logic fires
    assert_no_difference "CharacterSkill.count" do
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        target_skill_level: 2
      )
    end
  end

  it "does not resolve prerequisites when decreasing current_skill_level" do
    @cs.update!(current_skill_level: 2)

    assert_no_difference "CharacterSkill.count" do
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 1
      )
    end
  end

  # CharacterMastery auto-update on increase

  it "updates CharacterMastery when current_skill_level increases" do
    cm =
      CharacterMastery.find_by(
        character: @char,
        mastery: masteries(:blade_sword)
      )

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sg.id,
      current_skill_level: 2
    )

    # blade_active_skill (level 2): mastery_level_req = 5
    assert_equal 5, cm.reload.current_mastery_level
  end

  it "adds warning when CharacterMastery is updated" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 2
      )

    assert result.warnings.any? { |w| w.include?("updated to") }
  end

  it "does not update CharacterMastery when level is already sufficient" do
    cm =
      CharacterMastery.find_by(
        character: @char,
        mastery: masteries(:blade_sword)
      )
    cm.update!(current_mastery_level: 10)

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sg.id,
      current_skill_level: 2
    )

    assert_equal 10, cm.reload.current_mastery_level
  end

  # character level auto-update on increase

  it "auto-updates character current_level when mastery exceeds it" do
    @char.update!(current_level: 0)
    cm =
      CharacterMastery.find_by(
        character: @char,
        mastery: masteries(:blade_sword)
      )
    cm.update!(current_mastery_level: 0)

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sg.id,
      current_skill_level: 2
    )

    # blade_active_skill mastery_level_req = 5 > 0
    assert_equal 5, @char.reload.current_level
  end

  it "adds warning when character level is auto-updated" do
    @char.update!(current_level: 0)
    cm =
      CharacterMastery.find_by(
        character: @char,
        mastery: masteries(:blade_sword)
      )
    cm.update!(current_mastery_level: 0)

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sg.id,
        current_skill_level: 2
      )

    assert result.warnings.any? { |w| w.include?("character.current_level") }
  end
end
