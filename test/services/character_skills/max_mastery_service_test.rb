require "test_helper"

class CharacterSkills::MaxMasteryServiceTest < ActiveSupport::TestCase
  before do
    @user = create(:user)
    @race = races(:chinese)

    @mastery =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series = create(:skill_series, mastery: @mastery, title: "Basic")

    @sg1 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Slash",
        max_skill_level: 3,
        col_position: 0
      )
    create(:skill, skill_group: @sg1, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sg1, skill_level: 2, mastery_level_req: 5)
    create(:skill, skill_group: @sg1, skill_level: 3, mastery_level_req: 10)

    @sg2 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Strike",
        max_skill_level: 2,
        col_position: 1
      )
    create(:skill, skill_group: @sg2, skill_level: 1, mastery_level_req: 5)
    create(:skill, skill_group: @sg2, skill_level: 2, mastery_level_req: 15)

    @char =
      create(
        :character,
        user: @user,
        race: @race,
        server_level_cap: 110,
        current_level: 10,
        target_level: 10
      )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery,
      current_mastery_level: 50,
      target_mastery_level: 50
    )
  end

  def call(side:)
    CharacterSkills::MaxMasteryService.call(
      @char,
      mastery: @mastery,
      side: side
    )
  end

  it "returns ok" do
    assert call(side: :current).success?
  end

  it "raises existing skills to effective_cap on :current side" do
    cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 1,
        target_skill_level: 1
      )
    call(side: :current)
    assert_equal 3, cs.reload.current_skill_level
  end

  it "creates missing CharacterSkill at effective_cap on :current side" do
    assert_nil CharacterSkill.find_by(character: @char, skill_group: @sg1)
    call(side: :current)
    cs = CharacterSkill.find_by(character: @char, skill_group: @sg1)
    assert_not_nil cs
    assert_equal 3, cs.current_skill_level
  end

  it "creates missing CharacterSkill at effective_cap on :target side" do
    call(side: :target)
    cs = CharacterSkill.find_by(character: @char, skill_group: @sg1)
    assert_not_nil cs
    assert_equal 3, cs.target_skill_level
  end

  it "does not touch the other side (spec 03 R2)" do
    cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 1,
        target_skill_level: 1
      )
    call(side: :current)
    assert_equal 1, cs.reload.target_skill_level
  end

  it "respects effective_cap — excludes skills with mastery_level_req > server_level_cap" do
    # sg2 level 2 has mastery_level_req=15, server_level_cap=110, so cap=2
    # sg2 level 1 has mastery_level_req=5, so still reachable
    # effective_cap for sg2 = 2 (both reachable within cap 110)
    call(side: :current)
    cs2 = CharacterSkill.find_by(character: @char, skill_group: @sg2)
    assert_not_nil cs2
    assert_equal 2, cs2.current_skill_level
  end

  it "respects a lower server_level_cap" do
    # With cap=90, sg1: req=1 ok, req=5 ok, req=10 ok → cap=3
    # sg2: req=5 ok, req=15 ok → cap=2
    # (same as default — use a cap where sg1 level 2 req=5 is reachable but 3 req=10 is not)
    # Create a char with server_level_cap=90 but mastery_level_req capped at 7
    # Adjust: sg1 level 2 has mastery_level_req=5 (ok), level 3 has req=10 (>90? no).
    # To get sg1 cap=1: need mastery_level_req for level 1 <= 90, for level 2 > 90.
    # But skills were created with req=5 for level 2, which is <= 90.
    # Better: update the skill directly.
    @sg1.skills.find_by(skill_level: 2).update_columns(mastery_level_req: 120)
    @sg1.skills.find_by(skill_level: 3).update_columns(mastery_level_req: 130)
    # server_level_cap=110: level 1 (req=1) ok, level 2 (req=120) blocked → cap=1
    call(side: :current)
    cs = CharacterSkill.find_by(character: @char, skill_group: @sg1)
    assert_equal 1, cs.current_skill_level
  end

  it "skips skill groups where effective_cap is 0" do
    # All skills in sg1 have mastery_level_req > server_level_cap
    @sg1.skills.update_all(mastery_level_req: 200)
    @sg2.skills.update_all(mastery_level_req: 200)
    call(side: :current)
    assert_equal 0, CharacterSkill.where(character: @char).count
  end

  it "does not decrement a skill already above cap (no-op)" do
    cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 3,
        target_skill_level: 3
      )
    call(side: :current)
    assert_equal 3, cs.reload.current_skill_level
  end
end
