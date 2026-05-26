require "test_helper"

class CharacterSkills::AddServiceTest < ActiveSupport::TestCase
  # --------- helpers --------------------------------------------------------

  def fresh_char
    Character.create!(
      name: "Fresh",
      race: races(:chinese),
      current_level: 0,
      target_level: 0
    )
  end

  # --------- validations ----------------------------------------------------

  it "fails when skill_group does not exist" do
    result =
      CharacterSkills::AddService.call(
        characters(:one),
        skill_group_id: 0,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("SkillGroup must exist") }
  end

  it "fails when skill_group race differs from character race" do
    result =
      CharacterSkills::AddService.call(
        characters(:one),
        skill_group_id: skill_groups(:warrior_skills).id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("race") }
  end

  it "fails when skill already added to this character" do
    result =
      CharacterSkills::AddService.call(
        characters(:one),
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        current_skill_level: 1
      )

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("already been added") }
  end

  it "fails when current_skill_level is nil" do
    result =
      CharacterSkills::AddService.call(
        characters(:one),
        skill_group_id: skill_groups(:cold_force_skills).id
      )

    assert_not result.success?
    assert result.errors.any? { |e|
             e.include?("current_skill_level is required")
           }
  end

  it "fails when current_skill_level is negative" do
    result =
      CharacterSkills::AddService.call(
        characters(:one),
        skill_group_id: skill_groups(:cold_force_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
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
        skill_group_id: skill_groups(:cold_force_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        current_skill_level: 0
      )

    assert result.success?
    assert_equal 0, result.data.current_skill_level
  end

  it "persists CharacterSkill to the database" do
    assert_difference "CharacterSkill.count", 1 do
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
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
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        current_skill_level: 1
      )
    end
  end

  it "sets mastery levels from the skill mastery_level_req" do
    char = fresh_char
    CharacterSkills::AddService.call(
      char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      current_skill_level: 1,
      target_skill_level: 2
    )

    cm =
      CharacterMastery.find_by(
        character: char,
        mastery: masteries(:blade_sword)
      )
    # blade_passive_skill (level 1): mastery_level_req = 1
    # blade_active_skill  (level 2): mastery_level_req = 5
    assert_equal 1, cm.current_mastery_level
    assert_equal 5, cm.target_mastery_level
  end

  it "adds warning when CharacterMastery is auto-created" do
    result =
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        current_skill_level: 1
      )

    assert result.warnings.any? { |w| w.include?("created automatically") }
  end

  # --------- CharacterMastery auto-update ----------------------------------

  it "updates CharacterMastery.current_mastery_level when too low" do
    char = fresh_char
    mastery = masteries(:blade_sword)
    cm =
      CharacterMastery.create!(
        character: char,
        mastery:,
        current_mastery_level: 0
      )

    CharacterSkills::AddService.call(
      char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      current_skill_level: 2
    )

    # blade_active_skill (level 2): mastery_level_req = 5
    assert_equal 5, cm.reload.current_mastery_level
  end

  it "adds warning when CharacterMastery is updated" do
    char = fresh_char
    CharacterMastery.create!(
      character: char,
      mastery: masteries(:blade_sword),
      current_mastery_level: 0
    )

    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        current_skill_level: 2
      )

    assert result.warnings.any? { |w| w.include?("updated to") }
  end

  it "does not update CharacterMastery when level is already sufficient" do
    char = fresh_char
    mastery = masteries(:blade_sword)
    cm =
      CharacterMastery.create!(
        character: char,
        mastery:,
        current_mastery_level: 10
      )

    CharacterSkills::AddService.call(
      char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      current_skill_level: 1
    )

    assert_equal 10, cm.reload.current_mastery_level
  end

  # --------- character level auto-update -----------------------------------

  it "auto-updates character current_level when mastery exceeds it" do
    char = fresh_char # current_level = 0
    CharacterSkills::AddService.call(
      char,
      skill_group_id: skill_groups(:sword_mastery_skills).id,
      current_skill_level: 1 # mastery_level_req = 1 > 0
    )

    assert_equal 1, char.reload.current_level
  end

  it "adds warning when character level is auto-updated" do
    char = fresh_char
    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: skill_groups(:sword_mastery_skills).id,
        current_skill_level: 1
      )

    assert result.warnings.any? { |w| w.include?("character.current_level") }
  end

  # --------- warnings accumulation ----------------------------------------

  it "warnings accumulate across prerequisite and mastery auto-creation" do
    # Adding spear (requires sword at 1) to a fresh char:
    #   1. CharacterMastery for blade_sword auto-created (sword prereq)
    #   2. character.current_level raised (sword mastery req > 0)
    #   3. character.target_level raised
    #   4. prerequisite 'Blade Skills' added automatically
    #   5. CharacterMastery for spear auto-created
    #   6. character.current_level raised again (spear mastery req > sword's)
    char =
      Character.create!(
        name: "Fresh",
        race: races(:chinese),
        current_level: 0,
        target_level: 0
      )

    result =
      CharacterSkills::AddService.call(
        char,
        skill_group_id: skill_groups(:spear_mastery_skills).id,
        current_skill_level: 1
      )

    assert result.success?
    assert result.warnings.any? { |w| w.include?("added automatically") },
           "must warn about auto-added prerequisite"
    assert result.warnings.any? { |w| w.include?("created automatically") },
           "must warn about auto-created CharacterMastery"
    assert result.warnings.any? { |w| w.include?("character.current_level") },
           "must warn about character level auto-update"
    assert result.warnings.size >= 4,
           "expected at least 4 accumulated warnings, got #{result.warnings.size}"
  end

  # --------- prerequisite resolution ---------------------------------------

  it "auto-adds prerequisite skill when not present" do
    char = fresh_char
    # spear requires sword at level 1; char has no skills yet
    assert_difference "CharacterSkill.count", 2 do
      CharacterSkills::AddService.call(
        char,
        skill_group_id: skill_groups(:spear_mastery_skills).id,
        current_skill_level: 1
      )
    end

    prereq_cs =
      CharacterSkill.find_by(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      )
    assert_not_nil prereq_cs
    assert_equal 1, prereq_cs.current_skill_level
  end

  it "adds warning when prerequisite is auto-added" do
    result =
      CharacterSkills::AddService.call(
        fresh_char,
        skill_group_id: skill_groups(:spear_mastery_skills).id,
        current_skill_level: 1
      )

    assert result.warnings.any? { |w| w.include?("added automatically") }
  end

  it "upgrades existing prerequisite when level is insufficient" do
    # characters(:one) already has sword at level 1; cold requires sword at 3
    result =
      CharacterSkills::AddService.call(
        characters(:one),
        skill_group_id: skill_groups(:cold_force_skills).id,
        current_skill_level: 1
      )

    assert result.success?
    assert_equal 3, character_skills(:one).reload.current_skill_level
    assert result.warnings.any? { |w|
             w.include?("Blade Skills") && w.include?("updated to 3")
           }
  end

  it "does not add or modify prerequisite when already at sufficient level" do
    # characters(:one) has sword at level 1; spear requires sword at 1 --- already met
    CharacterSkills::AddService.call(
      characters(:one),
      skill_group_id: skill_groups(:spear_mastery_skills).id,
      current_skill_level: 1
    )

    # sword should remain at level 1, not be duplicated
    assert_equal 1, character_skills(:one).reload.current_skill_level
    assert_equal 1,
                 CharacterSkill.where(
                   character: characters(:one),
                   skill_group: skill_groups(:sword_mastery_skills)
                 ).count
  end

  it "does not resolve prerequisites when current_skill_level is 0" do
    char = fresh_char
    # spear requires sword at level 1, but current_skill_level is 0 --- no prereq resolution
    assert_difference "CharacterSkill.count", 1 do
      CharacterSkills::AddService.call(
        char,
        skill_group_id: skill_groups(:spear_mastery_skills).id,
        current_skill_level: 0
      )
    end
  end
end
