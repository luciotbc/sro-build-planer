require "test_helper"

# Integration tests for the skill info panel and series info panel
# rendered inside the character edit view (014).
class SkillInfoPanelTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = races(:chinese)
    @mastery =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series = create(:skill_series, mastery: @mastery, title: "Basic Series")

    @sg_pre =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Guard",
        max_skill_level: 1
      )
    create(
      :skill,
      skill_group: @sg_pre,
      skill_level: 1,
      mastery_level_req: 1,
      sp_cost: 50,
      mp_cost: 10
    )

    @sg1 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Slash",
        max_skill_level: 3
      )
    create(
      :skill,
      skill_group: @sg1,
      skill_level: 1,
      mastery_level_req: 1,
      sp_cost: 100,
      mp_cost: 20
    )
    create(
      :skill,
      skill_group: @sg1,
      skill_level: 2,
      mastery_level_req: 5,
      sp_cost: 200,
      mp_cost: 30
    )
    create(
      :skill,
      skill_group: @sg1,
      skill_level: 3,
      mastery_level_req: 10,
      sp_cost: 300,
      mp_cost: 40
    )

    create(
      :skill_group_requirement,
      skill_group: @sg1,
      required_group: @sg_pre,
      required_skill_level: 1
    )

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
      current_mastery_level: 10,
      target_mastery_level: 10
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg1,
      current_skill_level: 2,
      target_skill_level: 2
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_pre,
      current_skill_level: 1,
      target_skill_level: 1
    )

    sign_in_as @user
  end

  def get_edit(side: :current)
    get edit_character_path(@char, side: side, mastery_id: @mastery.id)
  end

  # ---- dialog markup present ---------------------------------------------------

  it "skill rows include a dialog element for the info panel" do
    get_edit
    assert_select "dialog", minimum: 1
  end

  it "skill row info panel includes the skill group name as dialog heading" do
    get_edit
    assert_select "dialog", text: /Slash/
  end

  # ---- skill at level > 0: costs and requirements shown -----------------------

  it "skill info panel shows sp_cost for the current skill level" do
    get_edit
    # sg1 current_skill_level=2 → skill at level 2 has sp_cost=200
    assert_select "dialog", text: /200/
  end

  it "skill info panel shows mp_cost for the current skill level" do
    get_edit
    # sg1 current_skill_level=2 → skill at level 2 has mp_cost=30
    assert_select "dialog", text: /30/
  end

  it "skill info panel shows mastery_level_req for the current skill level" do
    get_edit
    # skill at level 2 has mastery_level_req=5
    assert_select "dialog", text: /5/
  end

  # ---- prerequisite list -------------------------------------------------------

  it "skill info panel lists prerequisite names" do
    get_edit
    # sg1 requires sg_pre (Guard) at level 1
    assert_select "dialog", text: /Guard/
  end

  # ---- skill at level 0: unlearned state --------------------------------------

  it "shows unlearned state when skill level is 0" do
    # Create a third group with no allocated CS → level=0
    sg_empty =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Cleave",
        max_skill_level: 2
      )
    create(:skill, skill_group: sg_empty, skill_level: 1, mastery_level_req: 1)
    get_edit
    assert_select "dialog", text: /Cleave/
    assert_includes response.body, "Not yet learned"
  end

  # ---- series info panel -------------------------------------------------------

  it "series header includes a dialog for the series info panel" do
    get_edit
    assert_select "dialog", text: /Basic Series/
  end

  it "series info panel lists skill group names" do
    get_edit
    assert_select "dialog", text: /Slash/
  end

  it "series info panel shows total skill count" do
    get_edit
    # 2 groups in @series: @sg_pre (Guard) and @sg1 (Slash)
    assert_select "dialog", text: /2 skills/
  end
end
