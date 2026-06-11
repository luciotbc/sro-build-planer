require "test_helper"

class HomeSkillWindowTest < ActionDispatch::IntegrationTest
  before do
    @race = create(:race, :chinese)
    @user = create(:user)
    @character =
      create(
        :character,
        user: @user,
        race: @race,
        name: "BuckTBC",
        current_level: 30,
        target_level: 110
      )

    @blade = create(:mastery, :blade, race: @race)
    @cold = create(:mastery, :cold, race: @race)

    @series = create(:skill_series, mastery: @blade, title: "Pierce series")
    @group =
      create(
        :skill_group,
        mastery: @blade,
        skill_series: @series,
        name: "Pierce I",
        max_skill_level: 42,
        col_position: 1
      )

    create(
      :character_mastery,
      character: @character,
      mastery: @blade,
      current_mastery_level: 30,
      target_mastery_level: 60
    )
    create(
      :character_skill,
      character: @character,
      skill_group: @group,
      current_skill_level: 9,
      target_skill_level: 12
    )

    sign_in_as(@user)
  end

  describe "GET / (logged in)" do
    it "shows the character identity bar" do
      get root_path

      assert_response :success
      assert_select "h1", text: "BuckTBC"
      assert_match "Chinese", response.body
    end

    it "shows the skills card with mastery type tabs" do
      get root_path

      assert_select "turbo-frame#skill_window"
      assert_match "Weapon", response.body
      assert_match "Force", response.body
    end

    it "shows the plan summary stat rows" do
      get root_path

      assert_select "#plan_summary" do
        assert_match "Skill points", response.body
        assert_match "Mastery total", response.body
        assert_match "Required level", response.body
      end
    end
  end

  describe "GET /skill_window" do
    it "renders the selected mastery with series and skill levels" do
      get skill_window_path(mastery_id: @blade.id)

      assert_response :success
      assert_select "turbo-frame#skill_window"
      assert_match "Blade", response.body
      assert_match "Pierce series", response.body
      assert_match "9", response.body
      assert_match "12", response.body
    end

    it "falls back to the first mastery of the requested type" do
      get skill_window_path(group: "Force")

      assert_response :success
      assert_match "Cold", response.body
    end

    it "requires authentication" do
      sign_out

      get skill_window_path

      assert_redirected_to new_session_path
    end
  end
end
