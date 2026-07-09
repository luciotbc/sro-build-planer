require "test_helper"

class CharactersShowTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    # Fresh race (no fixture masteries) so the nav reflects exactly the
    # masteries created here (the planner lists ALL race masteries, spec 07).
    @race = create(:race)
    @mastery = create(:mastery, race: @race, name: "Blade")
    @series = create(:skill_series, mastery: @mastery, row_position: 1)
    @sg =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
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
    assert_select ".char-bar-race", text: /#{Regexp.escape(@race.name)}/i
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

  it "shows empty state when the race has no masteries" do
    # Nav lists all race masteries (spec 07), so the empty state requires a
    # race with no masteries at all — not merely an unowned set.
    empty_char = create(:character, user: @user, race: create(:race))
    get character_path(empty_char)
    assert_response :success
    assert_match /no mastery/i, response.body
  end

  it "lists race masteries the character does not own" do
    create(:mastery, race: @race, name: "Spear", mastery_type: "Weapon")
    get character_path(@char)
    assert_match "Spear", response.body
  end

  # ---- sharing (spec 05 R11a/R13) -------------------------------------------

  describe "sharing card" do
    it "renders the visibility toggle" do
      get character_path(@char)
      assert_select "input[type=checkbox][name='character[public]']"
    end

    it "hides the share link while the build is private" do
      get character_path(@char)
      refute_includes response.body, shared_build_url(@char.share_token)
    end

    it "shows the share link once the build is public" do
      @char.update!(public: true)
      get character_path(@char)
      assert_includes response.body, shared_build_url(@char.share_token)
    end

    it "checks the toggle for a public build" do
      @char.update!(public: true)
      get character_path(@char)
      assert_select "input[name='character[public]'][checked]"
    end

    it "shows the private-state hint while the build is private" do
      get character_path(@char)
      assert_includes response.body,
                      I18n.t("characters.show.sharing.hint_private")
      refute_includes response.body,
                      I18n.t("characters.show.sharing.hint_public")
    end

    it "shows the public-state hint once the build is public" do
      @char.update!(public: true)
      get character_path(@char)
      assert_includes response.body,
                      I18n.t("characters.show.sharing.hint_public")
      refute_includes response.body,
                      I18n.t("characters.show.sharing.hint_private")
    end
  end

  # ---- out-of-cap groups hidden (spec 04 R5) -------------------------------

  describe "server-cap filtering" do
    it "hides a skill group whose lowest level requires mastery above the cap" do
      out =
        create(
          :skill_group,
          mastery: @mastery,
          skill_series: @series,
          name: "Beyond Cap"
        )
      create(
        :skill,
        skill_group: out,
        skill_level: 1,
        mastery_level_req: @char.server_level_cap + 1
      )
      get character_path(@char)
      assert_response :success
      refute_match "Beyond Cap", response.body
    end

    it "hides a series whose groups are all out of cap" do
      empty_series =
        create(
          :skill_series,
          mastery: @mastery,
          row_position: 2,
          title: "Ghost Series"
        )
      out =
        create(
          :skill_group,
          mastery: @mastery,
          skill_series: empty_series,
          name: "Beyond Cap"
        )
      create(
        :skill,
        skill_group: out,
        skill_level: 1,
        mastery_level_req: @char.server_level_cap + 1
      )
      get character_path(@char)
      refute_match "Ghost Series", response.body
    end

    it "still shows an out-of-cap group the character has allocated" do
      out =
        create(
          :skill_group,
          mastery: @mastery,
          skill_series: @series,
          name: "Beyond Cap"
        )
      create(
        :skill,
        skill_group: out,
        skill_level: 1,
        mastery_level_req: @char.server_level_cap + 1
      )
      create(
        :character_skill,
        character: @char,
        skill_group: out,
        current_skill_level: 1,
        target_skill_level: 1
      )
      get character_path(@char)
      assert_match "Beyond Cap", response.body
    end
  end
end
