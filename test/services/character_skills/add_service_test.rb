require "test_helper"

class CharacterSkills::AddServiceTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @european_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @spear_mastery = create(:mastery, race: @chinese_race)
    @cold_mastery = create(:mastery, race: @chinese_race)
    @warrior_mastery = create(:mastery, race: @european_race)
    @sword_sg =
      create(
        :skill_group,
        mastery: @blade_mastery,
        name: "Blade Skills",
        max_skill_level: 2
      )
    @spear_sg =
      create(:skill_group, mastery: @spear_mastery, name: "Spear Skills")
    @cold_sg =
      create(:skill_group, mastery: @cold_mastery, name: "Cold Force Skills")
    @warrior_sg = create(:skill_group, mastery: @warrior_mastery)
    create(:skill, skill_group: @sword_sg, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sword_sg, skill_level: 2, mastery_level_req: 5)
    create(:skill, skill_group: @spear_sg, skill_level: 1, mastery_level_req: 3)
    create(
      :skill_group_requirement,
      skill_group: @spear_sg,
      required_group: @sword_sg,
      required_skill_level: 1
    )
    create(
      :skill_group_requirement,
      skill_group: @cold_sg,
      required_group: @sword_sg,
      required_skill_level: 3
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
  end

  def fresh_char
    create(:character, race: @chinese_race, current_level: 0, target_level: 0)
  end

  # --------- validations ----------------------------------------------------

  it "fails when skill_group does not exist" do
    result =
      CharacterSkills::AddService.call(
        @char,
        skill_group_id: 0,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("SkillGroup must exist") }
  end

  it "fails when skill_group race differs from character race" do
    result =
      CharacterSkills::AddService.call(
        @char,
        skill_group_id: @warrior_sg.id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("race") }
  end

  it "fails when skill already added to this character" do
    result =
      CharacterSkills::AddService.call(
        @char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("already been added") }
  end

  it "fails when current_skill_level is nil" do
    result =
      CharacterSkills::AddService.call(@char, skill_group_id: @cold_sg.id)

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("current_skill_level is required")
           }
  end

  it "fails when current_skill_level is negative" do
    result =
      CharacterSkills::AddService.call(
        @char,
        skill_group_id: @cold_sg.id,
        current_skill_level: -1
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("current_skill_level") && e.include?(">= 0")
           }
  end

  it "fails when current_skill_level exceeds max_skill_level" do
    result =
      CharacterSkills::AddService.call(
        fresh_char,
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
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: @cold_sg.id,
        current_skill_level: 0,
        target_skill_level: -1
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("target_skill_level") && e.include?(">= 0")
           }
  end

  it "fails when target_skill_level exceeds max_skill_level" do
    result =
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0,
        target_skill_level: 3
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("target_skill_level") && e.include?("<= 2")
           }
  end

  # --------- happy path ----------------------------------------------------

  it "creates CharacterSkill with provided levels" do
    char = fresh_char
    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1,
        target_skill_level: 2
      )

    assert result.success?
    assert_instance_of CharacterSkill, result.data
    assert_equal 1, result.data.current_skill_level
    assert_equal 2, result.data.target_skill_level
  end

  it "defaults target_skill_level to 0 when not provided" do
    char = fresh_char
    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1
      )

    assert result.success?
    assert_equal 0, result.data.target_skill_level
  end

  it "accepts current_skill_level of 0" do
    char = fresh_char
    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 0
      )

    assert result.success?
    assert_equal 0, result.data.current_skill_level
  end

  it "persists CharacterSkill to the database" do
    assert_difference "CharacterSkill.count", 1 do
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1
      )
    end
  end

  # --------- CharacterMastery auto-create ----------------------------------

  it "auto-creates CharacterMastery when not present" do
    char = fresh_char
    assert_difference "CharacterMastery.count", 1 do
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1
      )
    end
  end

  it "sets mastery levels from the skill mastery_level_req" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 1,
      target_skill_level: 2
    )

    cm = CharacterMastery.find_by(character: char, mastery: @blade_mastery)
    assert_equal 1, cm.current_mastery_level
    assert_equal 5, cm.target_mastery_level
  end

  it "adds warning when CharacterMastery is auto-created" do
    result =
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 1
      )

    assert result.warnings.any? { |w| w.include?("created automatically") }
  end

  # --------- CharacterMastery auto-update ----------------------------------

  it "updates CharacterMastery.current_mastery_level when too low" do
    char = fresh_char
    cm =
      CharacterMastery.create!(
        character: char,
        mastery: @blade_mastery,
        current_mastery_level: 0
      )

    CharacterSkills::AddService.call(
      char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 2
    )

    assert_equal 5, cm.reload.current_mastery_level
  end

  it "adds warning when CharacterMastery is updated" do
    char = fresh_char
    CharacterMastery.create!(
      character: char,
      mastery: @blade_mastery,
      current_mastery_level: 0
    )

    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @sword_sg.id,
        current_skill_level: 2
      )

    assert result.warnings.any? { |w| w.include?("updated to") }
  end

  it "does not update CharacterMastery when level is already sufficient" do
    char = fresh_char
    cm =
      CharacterMastery.create!(
        character: char,
        mastery: @blade_mastery,
        current_mastery_level: 10
      )

    CharacterSkills::AddService.call(
      char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 1
    )

    assert_equal 10, cm.reload.current_mastery_level
  end

  # --------- character level auto-update -----------------------------------

  it "auto-updates character current_level when mastery exceeds it" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 1
    )

    assert_equal 1, char.reload.current_level
  end

  it "character level is set correctly when mastery is auto-created" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: @sword_sg.id,
      current_skill_level: 1
    )

    # per spec 01 R1: current_level = MAX(mastery levels) = mastery_level_req
    assert_equal 1, char.reload.current_level
  end

  # --------- warnings accumulation ----------------------------------------

  it "warnings accumulate across prerequisite and mastery auto-creation" do
    char = create(:character, race: @chinese_race)

    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 1
      )

    assert result.success?
    assert result.warnings.any? { |w| w.include?("added automatically") },
           "must warn about auto-added prerequisite"
    assert result.warnings.any? { |w| w.include?("created automatically") },
           "must warn about auto-created CharacterMastery"
    # character level update is now handled silently by the CharacterMastery callback (spec 01 R1)
    assert result.warnings.size >= 3,
           "expected at least 3 accumulated warnings, got #{result.warnings.size}"
  end

  # --------- prerequisite resolution ---------------------------------------

  it "auto-adds prerequisite skill when not present" do
    char = fresh_char
    assert_difference "CharacterSkill.count", 2 do
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 1
      )
    end

    prereq_cs = CharacterSkill.find_by(character: char, skill_group: @sword_sg)
    assert_not_nil prereq_cs
    assert_equal 1, prereq_cs.current_skill_level
  end

  it "adds warning when prerequisite is auto-added" do
    result =
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 1
      )

    assert result.warnings.any? { |w| w.include?("added automatically") }
  end

  it "upgrades existing prerequisite when level is insufficient" do
    result =
      CharacterSkills::AddService.call(
        @char,
        skill_group_id: @cold_sg.id,
        current_skill_level: 1
      )

    assert result.success?
    assert_equal 3, @cs.reload.current_skill_level
    assert result.warnings.any? { |w|
             w.include?("Blade Skills") && w.include?("updated to 3")
           }
  end

  it "does not add or modify prerequisite when already at sufficient level" do
    CharacterSkills::AddService.call(
      @char,
      skill_group_id: @spear_sg.id,
      current_skill_level: 1
    )

    assert_equal 1, @cs.reload.current_skill_level
    assert_equal(
      1,
      CharacterSkill.where(character: @char, skill_group: @sword_sg).count
    )
  end

  it "does not resolve prerequisites when current_skill_level is 0" do
    char = fresh_char
    assert_difference "CharacterSkill.count", 1 do
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 0
      )
    end
  end

  # --------- target-side cascade (spec 03 R2) ----------------------------------

  it "auto-adds prerequisite on target side when target_skill_level > 0" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: @spear_sg.id,
      current_skill_level: 0,
      target_skill_level: 1
    )

    prereq = CharacterSkill.find_by(character: char, skill_group: @sword_sg)
    assert_not_nil prereq, "sword_sg prereq must be auto-added"
    assert_equal 1, prereq.target_skill_level
    assert_equal 0,
                 prereq.current_skill_level,
                 "current side must not be touched"
  end

  it "does not resolve target prerequisites when target_skill_level is 0" do
    char = fresh_char
    assert_difference "CharacterSkill.count", 1 do
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 0,
        target_skill_level: 0
      )
    end
  end

  it "escalates target_mastery_level from target-side prereq's mastery_level_req" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: @spear_sg.id,
      current_skill_level: 0,
      target_skill_level: 1
    )

    cm = CharacterMastery.find_by(character: char, mastery: @blade_mastery)
    assert_not_nil cm
    assert_equal 1,
                 cm.target_mastery_level,
                 "blade mastery_level_req for sword at level 1 is 1"
    assert_equal 0,
                 cm.current_mastery_level,
                 "current mastery must not be touched"
  end

  it "cascades both sides independently" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: @spear_sg.id,
      current_skill_level: 1,
      target_skill_level: 1
    )

    prereq = CharacterSkill.find_by(character: char, skill_group: @sword_sg)
    assert_not_nil prereq
    assert_equal 1, prereq.current_skill_level
    assert_equal 1, prereq.target_skill_level
  end

  it "target cascade does not block when current_skill_level is 0" do
    char = fresh_char
    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: @spear_sg.id,
        current_skill_level: 0,
        target_skill_level: 1
      )

    assert result.success?
  end
end
