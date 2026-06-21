require "test_helper"

# Structural tests validating mobile-responsive HTML requirements (task 016).
# CSS behaviour (overflow-x, touch targets) is verified in Chrome mobile
# emulation; these tests guard the underlying HTML structure.
class MobileResponsiveTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = races(:chinese)
    @mastery_a =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @mastery_b =
      create(:mastery, race: @race, name: "Spear", mastery_type: "Weapon")
    @char =
      create(
        :character,
        user: @user,
        race: @race,
        server_level_cap: 110,
        current_level: 5,
        target_level: 5
      )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_a,
      current_mastery_level: 0,
      target_mastery_level: 0
    )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery_b,
      current_mastery_level: 0,
      target_mastery_level: 0
    )
    sign_in_as @user
  end

  # ---- viewport meta (mobile-safe base) ----------------------------------------

  it "layout includes device-width viewport meta" do
    get character_path(@char)
    assert_response :success
    assert_select "meta[name='viewport'][content*='width=device-width']"
  end

  # ---- mastery tab navigation on show page ------------------------------------

  it "show page renders mastery type tab bar" do
    get character_path(@char)
    assert_select ".ro-tabs"
  end

  it "show page renders mastery sub-tab bar for each type" do
    get character_path(@char)
    assert_select ".ro-subtabs"
  end

  it "show page sub-tabs contain individual mastery links" do
    get character_path(@char)
    assert_select ".ro-subtab", minimum: 2
  end

  # ---- editor touch targets ---------------------------------------------------

  it "edit page has range slider for mastery level (touch-friendly)" do
    series = create(:skill_series, mastery: @mastery_a)
    sg =
      create(
        :skill_group,
        mastery: @mastery_a,
        skill_series: series,
        max_skill_level: 3
      )
    create(:skill, skill_group: sg, skill_level: 1, mastery_level_req: 1)
    get edit_character_path(@char, side: :current, mastery_id: @mastery_a.id)
    assert_response :success
    assert_select "input[type='range']"
  end

  it "edit page stepper buttons use fs-step-btn class (44px touch target)" do
    series = create(:skill_series, mastery: @mastery_a)
    sg =
      create(
        :skill_group,
        mastery: @mastery_a,
        skill_series: series,
        max_skill_level: 3
      )
    create(:skill, skill_group: sg, skill_level: 1, mastery_level_req: 1)
    get edit_character_path(@char, side: :current, mastery_id: @mastery_a.id)
    assert_select ".fs-step-btn", minimum: 2
  end

  # ---- overlays (drawer / sheet) on mobile ------------------------------------

  it "chars drawer uses dialog.drawer (right-pinned overlay)" do
    get character_path(@char)
    assert_select "dialog.drawer"
  end

  it "skill info panels use dialog.sheet (bottom-pinned overlay)" do
    series = create(:skill_series, mastery: @mastery_a)
    sg =
      create(
        :skill_group,
        mastery: @mastery_a,
        skill_series: series,
        max_skill_level: 3
      )
    create(:skill, skill_group: sg, skill_level: 1, mastery_level_req: 1)
    create(
      :character_skill,
      character: @char,
      skill_group: sg,
      current_skill_level: 1,
      target_skill_level: 1
    )
    get edit_character_path(@char, side: :current, mastery_id: @mastery_a.id)
    assert_select "dialog.sheet", minimum: 1
  end
end
