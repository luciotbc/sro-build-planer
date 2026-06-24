require "test_helper"

class CharacterSkillEditorTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    # Fresh race (no fixture masteries) so the nav reflects exactly the
    # masteries created here (the editor lists ALL race masteries, spec 07).
    @race = create(:race)
    @mastery =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series = create(:skill_series, mastery: @mastery, title: "Basic")
    @sg1 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Slash",
        max_skill_level: 3
      )
    @sg2 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Cut",
        max_skill_level: 5
      )
    create(
      :skill,
      skill_group: @sg1,
      skill_level: 1,
      sp_cost: 100,
      mastery_level_req: 1
    )
    create(
      :skill,
      skill_group: @sg1,
      skill_level: 2,
      sp_cost: 200,
      mastery_level_req: 5
    )
    create(
      :skill,
      skill_group: @sg2,
      skill_level: 1,
      sp_cost: 50,
      mastery_level_req: 1
    )

    @char = create(:character, user: @user, race: @race, server_level_cap: 110)
    @cm =
      create(
        :character_mastery,
        character: @char,
        mastery: @mastery,
        current_mastery_level: 10,
        target_mastery_level: 20
      )
    @cs1 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 1,
        target_skill_level: 2
      )
    @cs2 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg2,
        current_skill_level: 0,
        target_skill_level: 1
      )

    sign_in_as @user
  end

  # ---- routing / auth -------------------------------------------------------

  it "redirects unauthenticated access to login" do
    sign_out
    get edit_character_path(@char, side: :current)
    assert_redirected_to new_session_path
  end

  it "returns 404 for another user's character" do
    other_char = create(:character, user: create(:user), race: @race)
    get edit_character_path(other_char, side: :current)
    assert_response :not_found
  end

  # ---- side param -----------------------------------------------------------

  it "renders the edit view for side=current" do
    get edit_character_path(@char, side: :current)
    assert_response :success
    assert_match /current/i, response.body
  end

  it "renders the edit view for side=target" do
    get edit_character_path(@char, side: :target)
    assert_response :success
    assert_match /planned/i, response.body
  end

  it "defaults to side=current when side param is missing" do
    get edit_character_path(@char)
    assert_response :success
  end

  it "rejects an invalid side param" do
    get edit_character_path(@char, side: :invalid)
    assert_redirected_to character_path(@char)
  end

  # ---- content loaded -------------------------------------------------------

  it "renders the mastery name in the editor" do
    get edit_character_path(@char, side: :current)
    assert_match "Blade", response.body
  end

  it "renders the series name" do
    get edit_character_path(@char, side: :current)
    assert_match "Basic", response.body # series title
  end

  it "renders skill group names in the editor" do
    get edit_character_path(@char, side: :current)
    assert_match "Slash", response.body
    assert_match "Cut", response.body
  end

  it "shows the current skill level for side=current" do
    get edit_character_path(@char, side: :current)
    assert_select "[data-stepper-level-value='1']"
  end

  it "shows the target skill level for side=target" do
    get edit_character_path(@char, side: :target)
    assert_select "[data-stepper-level-value='2']"
  end

  it "computes effective cap respecting server_level_cap" do
    # sg1: max_skill_level=3; skills at levels 1 (req=1) and 2 (req=5)
    # server_level_cap=110: both reachable -> highest reachable = 2
    # effective_cap = min(2, 3) = 2 (spec 04 R4)
    get edit_character_path(@char, side: :current)
    assert_select "[data-stepper-max-value='2']"
  end

  # ---- series collapse (010/03) -------------------------------------------

  it "renders series panels with collapsible controller" do
    get edit_character_path(@char, side: :current)
    assert_select "[data-controller~='collapsible']"
  end

  it "shows allocated/total skill counter for side=current" do
    # @cs1.current_skill_level=1 (allocated), @cs2.current_skill_level=0 (not)
    # -> 1 out of 2 skills allocated in series "Basic"
    get edit_character_path(@char, side: :current)
    assert_match "1/2", response.body
  end

  it "shows allocated/total skill counter for side=target" do
    # @cs1.target_skill_level=2 (allocated), @cs2.target_skill_level=1 (allocated)
    # -> 2 out of 2 skills allocated in series "Basic"
    get edit_character_path(@char, side: :target)
    assert_match "2/2", response.body
  end

  it "skill rows have stepper url and side data attributes wired" do
    get edit_character_path(@char, side: :current)
    assert_select "[data-stepper-url-value]"
    assert_select "[data-stepper-side-value='current']"
  end

  # ---- all race masteries listed (spec 07) ---------------------------------

  it "lists race masteries the character does not own" do
    create(:mastery, race: @race, name: "Spear", mastery_type: "Weapon")
    get edit_character_path(@char, side: :current)
    assert_select "a[data-mastery-tabs-target='masteryTab']", text: "Spear"
  end

  it "orders mastery sub-tabs by id (in-game order)" do
    second =
      create(:mastery, race: @race, name: "Spear", mastery_type: "Weapon")
    get edit_character_path(@char, side: :current)
    ids =
      css_select("a[data-mastery-tabs-target='masteryTab']").map do |a|
        a["data-mastery-id"].to_i
      end
    assert_equal [@mastery.id, second.id], ids
  end
end
