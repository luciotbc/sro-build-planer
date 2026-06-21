require "test_helper"

class CharactersShowTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = races(:chinese)
    @mastery = create(:mastery, race: @race, name: "Blade")
    @sg =
      create(
        :skill_group,
        mastery: @mastery,
        name: "Blade Skills",
        max_skill_level: 3
      )
    create(:skill, skill_group: @sg, skill_level: 1, sp_cost: 100)
    create(:skill, skill_group: @sg, skill_level: 2, sp_cost: 200)

    @char = create(:character, user: @user, race: @race, name: "Blade Lord")
    @cm =
      create(
        :character_mastery,
        character: @char,
        mastery: @mastery,
        current_mastery_level: 50,
        target_mastery_level: 80
      )
    @cs =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg,
        current_skill_level: 1,
        target_skill_level: 2
      )

    sign_in_as @user
  end

  it "renders the character bar with the character's name" do
    get character_path(@char)
    assert_response :success
    assert_select ".char-bar-name", text: "Blade Lord"
  end

  it "renders the character bar with the race" do
    get character_path(@char)
    assert_select ".char-bar-race", text: /Chinese/i
  end

  it "renders the character bar with the server level cap" do
    get character_path(@char)
    assert_match "110", response.body
  end

  it "shows the active mastery name" do
    get character_path(@char)
    assert_match "Blade", response.body
  end

  it "shows current skill level" do
    get character_path(@char)
    assert_select "[data-skill-current]", text: "1"
  end

  it "shows planned skill level" do
    get character_path(@char)
    assert_select "[data-skill-planned]", text: "2"
  end

  it "renders Edit Current link with side=current" do
    get character_path(@char)
    assert_select "a[href*='side=current']"
  end

  it "renders Edit Planned link with side=target" do
    get character_path(@char)
    assert_select "a[href*='side=target']"
  end

  it "renders Delete button" do
    get character_path(@char)
    assert_select "form[action=?]", character_path(@char)
  end

  it "shows empty state when character has no masteries" do
    @char.character_masteries.destroy_all
    @char.character_skills.destroy_all
    get character_path(@char)
    assert_response :success
    assert_match /no mastery/i, response.body
  end
end
