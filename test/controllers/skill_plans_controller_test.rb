require "test_helper"

class SkillPlansControllerTest < ActionDispatch::IntegrationTest
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
    (1..42).each do |lv|
      create(:skill, skill_group: @group, skill_level: lv, mastery_level_req: 1)
    end

    @character_mastery =
      create(
        :character_mastery,
        character: @character,
        mastery: @blade,
        current_mastery_level: 30,
        target_mastery_level: 60
      )
    @character_skill =
      create(
        :character_skill,
        character: @character,
        skill_group: @group,
        current_skill_level: 9,
        target_skill_level: 12
      )

    sign_in_as(@user)
  end

  describe "GET /skill_plan/edit" do
    it "requires authentication" do
      sign_out

      get edit_skill_plan_path

      assert_redirected_to new_session_path
    end

    it "renders the planned editor by default" do
      get edit_skill_plan_path

      assert_response :success
      assert_match "PLANNING", response.body
      assert_match "Pierce series", response.body
      assert_match "Pierce I", response.body
    end

    it "renders the current editor when kind=current" do
      get edit_skill_plan_path(kind: "current")

      assert_response :success
      assert_match "CURRENT", response.body
    end

    it "shows the mastery summary with levels" do
      get edit_skill_plan_path(mastery_id: @blade.id)

      assert_match "Blade", response.body
      assert_select "#mastery_summary"
    end
  end

  describe "PATCH /skill_plan/skills/:skill_group_id" do
    it "updates the planned level and replies with a turbo stream" do
      patch skill_skill_plan_path(@group.id),
            params: {
              kind: "future",
              level: 20
            },
            as: :turbo_stream

      assert_response :success
      assert_equal 20, @character_skill.reload.target_skill_level
      assert_match "plan_skill_#{@group.id}", response.body
      assert_match "mastery_summary", response.body
    end

    it "updates the current level when kind=current" do
      patch skill_skill_plan_path(@group.id),
            params: {
              kind: "current",
              level: 10
            },
            as: :turbo_stream

      assert_response :success
      assert_equal 10, @character_skill.reload.current_skill_level
    end

    it "creates the character skill when missing" do
      other_group =
        create(
          :skill_group,
          mastery: @blade,
          skill_series: @series,
          name: "Pierce II",
          max_skill_level: 42,
          col_position: 2
        )
      create(
        :skill,
        skill_group: other_group,
        skill_level: 1,
        mastery_level_req: 1
      )

      patch skill_skill_plan_path(other_group.id),
            params: {
              kind: "future",
              level: 1
            },
            as: :turbo_stream

      assert_response :success
      cs = @character.character_skills.find_by(skill_group: other_group)
      assert_equal 1, cs.target_skill_level
    end

    it "rejects a level above the group cap" do
      patch skill_skill_plan_path(@group.id),
            params: {
              kind: "future",
              level: 99
            },
            as: :turbo_stream

      assert_response :unprocessable_entity
      assert_equal 12, @character_skill.reload.target_skill_level
    end
  end

  describe "PATCH /skill_plan/masteries/:mastery_id" do
    it "updates the planned mastery level" do
      patch mastery_skill_plan_path(@blade.id),
            params: {
              kind: "future",
              level: 80
            },
            as: :turbo_stream

      assert_response :success
      assert_equal 80, @character_mastery.reload.target_mastery_level
    end
  end

  describe "POST /skill_plan/masteries/:mastery_id/max_skills" do
    it "raises every planned skill of the mastery to its cap" do
      post max_skills_skill_plan_path(@blade.id),
           params: {
             kind: "future"
           },
           as: :turbo_stream

      assert_response :success
      assert_equal 42, @character_skill.reload.target_skill_level
    end
  end

  describe "POST /skill_plan/masteries/:mastery_id/clear" do
    it "zeroes the planned mastery and its skills" do
      post clear_skill_plan_path(@blade.id),
           params: {
             kind: "future"
           },
           as: :turbo_stream

      assert_response :success
      assert_equal 0, @character_mastery.reload.target_mastery_level
      assert_equal 0, @character_skill.reload.target_skill_level
      assert_equal 9, @character_skill.current_skill_level
    end
  end
end
