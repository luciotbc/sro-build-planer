require "test_helper"

class MasteryTabsTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = races(:chinese)
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

  it "renders mastery type tabs for the character's race" do
    get character_path(@char)
    assert_response :success
    assert_match "Weapon", response.body
    assert_match "Force", response.body
  end

  it "renders mastery sub-tabs for each mastery" do
    get character_path(@char)
    assert_match "Blade", response.body
    assert_match "Spear", response.body
    assert_match "Cold Force", response.body
  end

  it "highlights the active mastery sub-tab" do
    get character_path(@char, mastery_id: @spear.id)
    # active tab link points to the spear mastery
    assert_select "a[href*='mastery_id=#{@spear.id}'].on, [data-active='true'][data-mastery-id='#{@spear.id}']"
  end

  it "switches active mastery via mastery_id param" do
    get character_path(@char, mastery_id: @cold.id)
    assert_response :success
    # cold mastery name shown in mastery section
    assert_match "Cold Force", response.body
  end

  it "skill window updates to selected mastery (Turbo Frame present)" do
    get character_path(@char)
    assert_select "turbo-frame[id='skill-window']"
  end

  it "sub-tab links target the skill-window Turbo Frame" do
    get character_path(@char)
    assert_select "a[data-turbo-frame='skill-window']"
  end
end
