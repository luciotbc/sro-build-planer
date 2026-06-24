require "test_helper"

class MasteryTabsTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    # Fresh race (no fixture masteries) so the nav reflects exactly the
    # masteries created here (the editor/planner list ALL race masteries, spec 07).
    @race = create(:race)
    # Force < Weapon alphabetically → Force is first group on initial render
    @blade =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @spear =
      create(:mastery, race: @race, name: "Spear", mastery_type: "Weapon")
    @cold =
      create(:mastery, race: @race, name: "Cold Force", mastery_type: "Force")
    @sg = create(:skill_group, mastery: @blade, name: "Blade Skills")

    @char = create(:character, user: @user, race: @race)
    create(
      :character_mastery,
      character: @char,
      mastery: @blade,
      current_mastery_level: 10,
      target_mastery_level: 20
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @spear,
      current_mastery_level: 5,
      target_mastery_level: 10
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @cold,
      current_mastery_level: 0,
      target_mastery_level: 30
    )

    sign_in_as @user
  end

  # — Rendering —

  it "renders mastery type tabs for the character's race" do
    get character_path(@char)
    assert_response :success
    assert_match "Weapon", response.body
    assert_match "Force", response.body
  end

  it "renders mastery sub-tabs for each mastery in the HTML" do
    get character_path(@char)
    assert_match "Blade", response.body
    assert_match "Spear", response.body
    assert_match "Cold Force", response.body
  end

  it "skill window Turbo Frame is present" do
    get character_path(@char)
    assert_select "turbo-frame[id='skill-window']"
  end

  it "sub-tab links target the skill-window Turbo Frame" do
    get character_path(@char)
    assert_select "a[data-turbo-frame='skill-window']"
  end

  # — Initial render invariants (spec 07) —

  it "first group (Force) pill is active on initial render" do
    get character_path(@char)
    # Force < Weapon alphabetically — Force pill must have class `on`
    assert_select "button[data-mastery-type='Force'].on"
    assert_select "button[data-mastery-type='Weapon'].on", count: 0
  end

  it "first mastery of first group (Cold Force) sub-tab is active on initial render" do
    get character_path(@char)
    assert_select "a[data-mastery-id='#{@cold.id}'].on"
    assert_select "a[data-mastery-id='#{@blade.id}'].on", count: 0
    assert_select "a[data-mastery-id='#{@spear.id}'].on", count: 0
  end

  it "Force panel is visible, Weapon panel is hidden on initial render" do
    get character_path(@char)
    assert_select "div[data-mastery-type='Force']:not(.hidden)"
    assert_select "div[data-mastery-type='Weapon'].hidden"
  end

  # — mastery_id param —

  it "mastery_id param activates the correct sub-tab" do
    get character_path(@char, mastery_id: @spear.id)
    assert_select "a[data-mastery-id='#{@spear.id}'].on"
    assert_select "a[data-mastery-id='#{@blade.id}'].on", count: 0
  end

  it "mastery_id param activates the correct group pill" do
    get character_path(@char, mastery_id: @spear.id)
    assert_select "button[data-mastery-type='Weapon'].on"
    assert_select "button[data-mastery-type='Force'].on", count: 0
  end

  it "mastery_id param shows the correct group panel" do
    get character_path(@char, mastery_id: @spear.id)
    assert_select "div[data-mastery-type='Weapon']:not(.hidden)"
    assert_select "div[data-mastery-type='Force'].hidden"
  end

  # — Stimulus controller wiring —

  it "section uses mastery-tabs controller" do
    get character_path(@char)
    assert_select "[data-controller='mastery-tabs']"
  end

  it "type pills have mastery-tabs target and action" do
    get character_path(@char)
    assert_select "button[data-mastery-tabs-target='typeTab'][data-action='mastery-tabs#selectType']"
  end

  it "sub-tab links have mastery-tabs target and action" do
    get character_path(@char)
    assert_select "a[data-mastery-tabs-target='masteryTab'][data-action='mastery-tabs#selectMastery']"
  end

  # — Empty state (INV-2 edge case) —

  it "shows empty state when the race has no masteries" do
    # Nav lists all race masteries (spec 07), so the empty state requires a
    # race with no masteries at all — not merely an unowned set.
    empty_char = create(:character, user: @user, race: create(:race))
    get character_path(empty_char)
    assert_response :success
    assert_select "[data-controller='mastery-tabs']", count: 0
  end

  # — Unowned masteries still listed (spec 07) —

  it "lists masteries the character does not own" do
    # @char owns blade/spear/cold; add an unowned one — it must still appear.
    create(:mastery, race: @race, name: "Heuksal", mastery_type: "Weapon")
    get character_path(@char)
    assert_match "Heuksal", response.body
  end
end
