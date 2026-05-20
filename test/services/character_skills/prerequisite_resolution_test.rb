require "test_helper"

# Tests the recursive DFS algorithm shared by AddService and UpdateService.
# Each branch of the spec is exercised in isolation.
#
# Fixture graph (relevant edges):
#   spear_mastery_skills  → sword_mastery_skills (required_skill_level: 1)
#   cold_force_skills     → sword_mastery_skills (required_skill_level: 3)
#
# Dynamic requirements created inside individual tests extend this graph
# for 3-level chain and cycle scenarios.
class CharacterSkills::PrerequisiteResolutionTest < ActiveSupport::TestCase
  def fresh_char
    Character.create!(
      name: "Fresh",
      race: races(:chinese),
      current_level: 0,
      target_level: 0
    )
  end

  def add_skill(char, sg_fixture, level)
    CharacterSkills::AddService.call(
      char,
      skill_group_id: skill_groups(sg_fixture).id,
      current_skill_level: level
    )
  end

  # ───────── branch: does not exist → create ───────────────────────────────

  test "creates missing prerequisite automatically" do
    char = fresh_char
    add_skill(char, :spear_mastery_skills, 1)

    assert(
      CharacterSkill.exists?(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      )
    )
  end

  test "sets created prerequisite to required_skill_level" do
    char = fresh_char
    add_skill(char, :spear_mastery_skills, 1)

    cs =
      CharacterSkill.find_by(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      )
    assert_equal 1, cs.current_skill_level
    assert_equal 1, cs.target_skill_level
  end

  # ───────── branch: exists, level sufficient → skip ───────────────────────

  test "does not modify prerequisite when current_skill_level is already sufficient" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:sword_mastery_skills),
      current_skill_level: 2,
      target_skill_level: 2
    )

    add_skill(char, :spear_mastery_skills, 1)

    cs =
      CharacterSkill.find_by(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      )
    assert_equal 2, cs.current_skill_level
  end

  test "does not emit a warning when prerequisite is already sufficient" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:sword_mastery_skills),
      current_skill_level: 2,
      target_skill_level: 2
    )

    result = add_skill(char, :spear_mastery_skills, 1)
    assert result.warnings.none? { |w|
             w.include?("sword") || w.include?("Blade")
           }
  end

  # ───────── branch: exists, level insufficient → upgrade ──────────────────

  test "upgrades prerequisite when current_skill_level is below required" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:sword_mastery_skills),
      current_skill_level: 0,
      target_skill_level: 0
    )

    add_skill(char, :spear_mastery_skills, 1)

    cs =
      CharacterSkill.find_by(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      )
    assert_equal 1, cs.current_skill_level
  end

  test "emits warning when prerequisite is upgraded" do
    char = fresh_char
    CharacterSkill.create!(
      character: char,
      skill_group: skill_groups(:sword_mastery_skills),
      current_skill_level: 0,
      target_skill_level: 0
    )

    result = add_skill(char, :spear_mastery_skills, 1)
    assert result.warnings.any? { |w| w.include?("updated to 1") }
  end

  # ───────── DFS: 3-level chain ─────────────────────────────────────────────

  # Graph after adding the dynamic edge spear → cold:
  #   spear → sword  (fixture, level 1)
  #   spear → cold   (dynamic, level 1)
  #   cold  → sword  (fixture, level 3)
  #
  # Adding spear creates sword (spear's direct dep, level 1),
  # then creates cold (dynamic dep), whose own dep on sword at 3 upgrades it.

  test "creates entire chain when no prerequisites exist (3 levels)" do
    char = fresh_char
    SkillGroupRequirement.create!(
      skill_group: skill_groups(:spear_mastery_skills),
      required_group: skill_groups(:cold_force_skills),
      required_skill_level: 1
    )

    result = add_skill(char, :spear_mastery_skills, 1)

    assert result.success?
    assert(
      CharacterSkill.exists?(
        character: char,
        skill_group: skill_groups(:cold_force_skills)
      ),
      "cold should have been created as a direct prerequisite of spear"
    )
    assert(
      CharacterSkill.exists?(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      ),
      "sword should have been created as a transitive prerequisite via cold"
    )
  end

  test "upgrades transitive prerequisite when existing skill is insufficient (3 levels)" do
    char = fresh_char
    # sword exists at 0 — below cold's requirement of 3
    sword_cs =
      CharacterSkill.create!(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills),
        current_skill_level: 0,
        target_skill_level: 0
      )
    SkillGroupRequirement.create!(
      skill_group: skill_groups(:spear_mastery_skills),
      required_group: skill_groups(:cold_force_skills),
      required_skill_level: 1
    )

    result = add_skill(char, :spear_mastery_skills, 1)

    assert result.success?
    assert(
      CharacterSkill.exists?(
        character: char,
        skill_group: skill_groups(:cold_force_skills)
      ),
      "cold should have been created"
    )
    # cold requires sword at 3; resolve_prerequisites must have upgraded it
    assert sword_cs.reload.current_skill_level >= 1,
           "sword must have been upgraded to satisfy cold's transitive requirement"
  end

  # ───────── cycle protection ───────────────────────────────────────────────

  # Cycle: spear → sword (fixture) → spear (dynamic)
  # The visited set prevents infinite recursion; the already_visited guard prevents
  # double-creation of the root skill mid-traversal.

  test "does not loop infinitely when prerequisites contain a cycle" do
    char = fresh_char
    SkillGroupRequirement.create!(
      skill_group: skill_groups(:sword_mastery_skills),
      required_group: skill_groups(:spear_mastery_skills),
      required_skill_level: 1
    )

    result = add_skill(char, :spear_mastery_skills, 1)
    assert result.success?
  end

  test "creates prerequisite exactly once despite diamond-shaped dependency graph" do
    char = fresh_char
    # Diamond: spear → sword (fixture) and spear → cold (dynamic) → sword (fixture)
    # sword is reachable via two paths but must be created only once.
    SkillGroupRequirement.create!(
      skill_group: skill_groups(:spear_mastery_skills),
      required_group: skill_groups(:cold_force_skills),
      required_skill_level: 1
    )

    add_skill(char, :spear_mastery_skills, 1)

    assert_equal(
      1,
      CharacterSkill.where(
        character: char,
        skill_group: skill_groups(:sword_mastery_skills)
      ).count,
      "sword must be created exactly once despite being reachable via two paths"
    )
  end
end
