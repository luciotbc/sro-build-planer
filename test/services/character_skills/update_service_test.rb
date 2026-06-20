require "test_helper"

class CharacterSkills::UpdateServiceTest < ActiveSupport::TestCase
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
    create(:skill, skill_group: @sword_sg, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sword_sg, skill_level: 2, mastery_level_req: 5)
    create(:skill, skill_group: @spear_sg, skill_level: 1, mastery_level_req: 3)
    create(
      :skill_group_requirement,
      skill_group: @spear_sg,
      required_group: @sword_sg,
      required_skill_level: 1
    )
    @char =
      create(:character, race: @chinese_race, current_level: 1, target_level: 1)
    @cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sword_sg,
        current_skill_level: 1,
        target_skill_level: 1
      )
    CharacterMastery.create!(
      character: @char,
      mastery: @blade_mastery,
      current_mastery_level: 1,
      target_mastery_level: 1
    )
  end

  def fresh_char
    create(:character, race: @chinese_race, current_level: 0, target_level: 0)
  end

  # --------- existence validation -------------------------------------------

  it "fails when CharacterSkill does not exist for the character" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  # --------- immutable fields -----------------------------------------------

  it "fails when character_id is provided" do
    other_char = create(:character, race: @chinese_race)
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        character_id: other_char.id
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
        skill_group_id: @sword_sg.id,
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
        skill_group_id: @sword_sg.id,
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
        skill_group_id: @sword_sg.id,
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
        skill_group_id: @sword_sg.id,
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
        skill_group_id: @sword_sg.id,
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
      skill_group_id: @sword_sg.id,
      current_skill_level: 2
    )

    assert_equal 2, @cs.reload.current_skill_level
  end

  it "updates target_skill_level" do
    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sword_sg.id,
      target_skill_level: 2
    )

    assert_equal 2, @cs.reload.target_skill_level
  end

  it "updates both levels in one call" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
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
      skill_group_id: @sword_sg.id,
      current_skill_level: 2
    )

    assert_equal 1, @cs.reload.target_skill_level
  end

  it "returns successful ServiceResult with CharacterSkill" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 2
      )

    assert result.success?
    assert_instance_of CharacterSkill, result.data
  end

  it "accepts current_skill_level of 0" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  it "accepts target_skill_level of 0" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        target_skill_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.target_skill_level
  end

  it "returns not found when skill_group_id does not match any CharacterSkill for the character" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("not found") }
  end

  # --------- blocking dependents on decrease --------------------------------

  it "fails when decreasing current_skill_level below a dependent's requirement" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 1,
      target_skill_level: 1
    )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("blocked by") }
    assert result.errors.any? { |e| e.include?("Spear Skills") }
  end

  it "does not block when dependent's current_skill_level is 0" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 0,
      target_skill_level: 1
    )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0
      )

    assert result.success?
  end

  it "does not block when no dependents exist for the character" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0
      )

    assert result.success?
    assert_equal 0, @cs.reload.current_skill_level
  end

  # --------- prerequisite resolution on increase ---------------------------

  it "does not resolve prerequisites when current_skill_level is not increasing" do
    assert_no_difference "CharacterSkill.count" do
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        target_skill_level: 2
      )
    end
  end

  it "does not resolve prerequisites when decreasing current_skill_level" do
    @cs.update!(current_skill_level: 2)

    assert_no_difference "CharacterSkill.count" do
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1
      )
    end
  end

  # CharacterMastery auto-update on increase

  it "updates CharacterMastery when current_skill_level increases" do
    cm = CharacterMastery.find_by(character: @char, mastery: @blade_mastery)

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 2
    )

    assert_equal 5, cm.reload.current_mastery_level
  end

  it "adds warning when CharacterMastery is updated" do
    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 2
      )

    assert result.warnings.any? { |w| w.include?("updated to") }
  end

  it "does not update CharacterMastery when level is already sufficient" do
    cm = CharacterMastery.find_by(character: @char, mastery: @blade_mastery)
    cm.update!(current_mastery_level: 10)

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 2
    )

    assert_equal 10, cm.reload.current_mastery_level
  end

  # character level auto-update on increase

  it "auto-updates character current_level when mastery exceeds it" do
    @char.update!(current_level: 0)
    cm = CharacterMastery.find_by(character: @char, mastery: @blade_mastery)
    cm.update!(current_mastery_level: 0)

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 2
    )

    assert_equal 5, @char.reload.current_level
  end

  it "no character level warning emitted (level maintained by callback)" do
    cm = CharacterMastery.find_by(character: @char, mastery: @blade_mastery)
    cm.update!(current_mastery_level: 0)

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 2
      )

    assert_not result.warnings.any? { |w|
                 w.include?("character.current_level")
               }
    assert_equal 5, @char.reload.current_level
  end

  # --------- target-side cascade (spec 03 R2) ---------------------------------

  it "fails when decreasing target_skill_level below dependent's target-side requirement" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 0,
      target_skill_level: 1
    )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        target_skill_level: 0
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("blocked by") && e.include?("Spear")
           }
  end

  it "does not block target decrease when only current-side dependent requires higher level" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 1,
      target_skill_level: 0
    )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        target_skill_level: 0
      )

    assert result.success?
  end

  it "does not block current decrease when only target-side dependent requires higher level" do
    CharacterSkill.create!(
      character: @char,
      skill_group: @spear_sg,
      current_skill_level: 0,
      target_skill_level: 1
    )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0
      )

    assert result.success?
  end

  it "cascades prerequisite onto target side when target_skill_level increases" do
    CharacterMastery.create!(
      character: @char,
      mastery: @spear_mastery,
      current_mastery_level: 0,
      target_mastery_level: 0
    )
    spear_cs =
      CharacterSkill.create!(
        character: @char,
        skill_group: @spear_sg,
        current_skill_level: 0,
        target_skill_level: 0
      )

    result =
      CharacterSkills::UpdateService.call(
        @char,
        skill_group_id: @spear_sg.id,
        target_skill_level: 1
      )

    assert result.success?
    sword_cs = CharacterSkill.find_by(character: @char, skill_group: @sword_sg)
    assert_not_nil sword_cs, "sword prereq must be auto-added on target side"
    assert_equal 1, sword_cs.target_skill_level
    assert_equal 1,
                 sword_cs.current_skill_level,
                 "current is already 1 from @char before block setup"
  end

  it "escalates target_mastery_level when target_skill_level increases" do
    cm = CharacterMastery.find_by(character: @char, mastery: @blade_mastery)
    cm.update!(target_mastery_level: 0)

    CharacterSkills::UpdateService.call(
      @char,
      skill_group_id: @sword_sg.id,
      target_skill_level: 2
    )

    assert_equal 5, cm.reload.target_mastery_level
    assert_equal 1,
                 cm.reload.current_mastery_level,
                 "current mastery must not be touched"
  end
end
