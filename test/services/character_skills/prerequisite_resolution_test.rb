require "test_helper"

# Tests the recursive DFS algorithm shared by AddService and UpdateService.
# Each branch of the spec is exercised in isolation.
#
# Graph (relevant edges):
#   spear_sg  --- sword_sg (required_skill_level: 1)
#   cold_sg   --- sword_sg (required_skill_level: 3)
#
# Dynamic requirements created inside individual tests extend this graph
# for 3-level chain and cycle scenarios.
class CharacterSkills::PrerequisiteResolutionTest < ActiveSupport::TestCase
  before do
    @chinese_race = create(:race)
    @blade_mastery = create(:mastery, race: @chinese_race)
    @spear_mastery = create(:mastery, race: @chinese_race)
    @cold_mastery = create(:mastery, race: @chinese_race)
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
  end

  def fresh_char
    create(:character, race: @chinese_race, current_level: 0, target_level: 0)
  end

  def add_skill(char, sg, level)
    CharacterSkills::AddService.call(
      char,
      skill_group_id: sg.id,
      current_skill_level: level
    )
  end

  # --------- branch: does not exist --- create -------------------------------

  it "creates missing prerequisite automatically" do
    char = fresh_char
    add_skill(char, @spear_sg, 1)

    assert CharacterSkill.exists?(character: char, skill_group: @sword_sg)
  end

  it "sets created prerequisite to required_skill_level" do
    char = fresh_char
    add_skill(char, @spear_sg, 1)

    cs = CharacterSkill.find_by(character: char, skill_group: @sword_sg)
    assert_equal 1, cs.current_skill_level
    assert_equal 1, cs.target_skill_level
  end

  # --------- branch: exists, level sufficient --- skip -----------------------

  it "does not modify prerequisite when current_skill_level is already sufficient" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: @sword_sg,
      current_skill_level: 2,
      target_skill_level: 2
    )

    add_skill(char, @spear_sg, 1)

    cs = CharacterSkill.find_by(character: char, skill_group: @sword_sg)
    assert_equal 2, cs.current_skill_level
  end

  it "does not emit a warning when prerequisite is already sufficient" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: @sword_sg,
      current_skill_level: 2,
      target_skill_level: 2
    )

    result = add_skill(char, @spear_sg, 1)
    assert result.warnings.none? { |w|
             w.include?("sword") || w.include?("Blade")
           }
  end

  # --------- branch: exists, level insufficient --- upgrade ------------------

  it "upgrades prerequisite when current_skill_level is below required" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: @sword_sg,
      current_skill_level: 0,
      target_skill_level: 0
    )

    add_skill(char, @spear_sg, 1)

    cs = CharacterSkill.find_by(character: char, skill_group: @sword_sg)
    assert_equal 1, cs.current_skill_level
  end

  it "emits warning when prerequisite is upgraded" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: @sword_sg,
      current_skill_level: 0,
      target_skill_level: 0
    )

    result = add_skill(char, @spear_sg, 1)
    assert result.warnings.any? { |w| w.include?("updated to 1") }
  end

  # --------- DFS: 3-level chain ---------------------------------------------

  it "creates entire chain when no prerequisites exist (3 levels)" do
    char = fresh_char
    SkillGroupRequirement.create!(
      skill_group: @spear_sg,
      required_group: @cold_sg,
      required_skill_level: 1
    )

    result = add_skill(char, @spear_sg, 1)

    assert result.success?
    assert(
      CharacterSkill.exists?(character: char, skill_group: @cold_sg),
      "cold should have been created as a direct prerequisite of spear"
    )
    assert(
      CharacterSkill.exists?(character: char, skill_group: @sword_sg),
      "sword should have been created as a transitive prerequisite via cold"
    )
  end

  it "upgrades transitive prerequisite when existing skill is insufficient (3 levels)" do
    char = fresh_char
    sword_cs =
      CharacterSkill.create!(
        character: char,
        skill_group: @sword_sg,
        current_skill_level: 0,
        target_skill_level: 0
      )
    SkillGroupRequirement.create!(
      skill_group: @spear_sg,
      required_group: @cold_sg,
      required_skill_level: 1
    )

    result = add_skill(char, @spear_sg, 1)

    assert result.success?
    assert(
      CharacterSkill.exists?(character: char, skill_group: @cold_sg),
      "cold should have been created"
    )
    assert sword_cs.reload.current_skill_level >= 1,
           "sword must have been upgraded to satisfy cold's transitive requirement"
  end

  # --------- cycle protection -----------------------------------------------

  it "does not loop infinitely when prerequisites contain a cycle" do
    char = fresh_char
    SkillGroupRequirement.create!(
      skill_group: @sword_sg,
      required_group: @spear_sg,
      required_skill_level: 1
    )

    result = add_skill(char, @spear_sg, 1)
    assert result.success?
  end

  it "creates prerequisite exactly once despite diamond-shaped dependency graph" do
    char = fresh_char
    SkillGroupRequirement.create!(
      skill_group: @spear_sg,
      required_group: @cold_sg,
      required_skill_level: 1
    )

    add_skill(char, @spear_sg, 1)

    assert_equal(
      1,
      CharacterSkill.where(character: char, skill_group: @sword_sg).count,
      "sword must be created exactly once despite being reachable via two paths"
    )
  end
end
