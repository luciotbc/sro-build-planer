require "test_helper"

class BulkSkillActionsControllerTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = "text/vnd.turbo-stream.html"

  before do
    @user = create(:user)
    @other_user = create(:user)
    @race = races(:chinese)

    @mastery1 =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series1 = create(:skill_series, mastery: @mastery1, title: "Basic")
    @sg1 =
      create(
        :skill_group,
        mastery: @mastery1,
        skill_series: @series1,
        name: "Slash",
        max_skill_level: 3
      )
    create(:skill, skill_group: @sg1, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sg1, skill_level: 2, mastery_level_req: 5)
    create(:skill, skill_group: @sg1, skill_level: 3, mastery_level_req: 10)

    @mastery2 =
      create(:mastery, race: @race, name: "Spear", mastery_type: "Weapon")
    @series2 = create(:skill_series, mastery: @mastery2, title: "Basic")
    @sg3 =
      create(
        :skill_group,
        mastery: @mastery2,
        skill_series: @series2,
        name: "Thrust",
        max_skill_level: 2
      )
    create(:skill, skill_group: @sg3, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sg3, skill_level: 2, mastery_level_req: 5)

    @char =
      create(
        :character,
        user: @user,
        race: @race,
        server_level_cap: 110,
        current_level: 10,
        target_level: 10
      )
    @cm1 =
      create(
        :character_mastery,
        character: @char,
        mastery: @mastery1,
        current_mastery_level: 50,
        target_mastery_level: 50
      )
    @cm2 =
      create(
        :character_mastery,
        character: @char,
        mastery: @mastery2,
        current_mastery_level: 50,
        target_mastery_level: 50
      )
    @cs1 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 1,
        target_skill_level: 1
      )
    @cs3 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg3,
        current_skill_level: 1,
        target_skill_level: 1
      )

    @other_char = create(:character, user: @other_user, race: @race)

    sign_in_as @user
  end

  def turbo_post(path, params)
    post path, params: params, headers: { "Accept" => TURBO_STREAM }
  end

  # ---- max_skills auth ---------------------------------------------------------

  it "redirects unauthenticated max_skills to login" do
    sign_out
    turbo_post max_skills_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_redirected_to new_session_path
  end

  it "returns 404 for another user's character on max_skills" do
    turbo_post max_skills_character_path(@other_char),
               { side: :current, mastery_id: @mastery1.id }
    assert_response :not_found
  end

  # ---- max_skills behavior -----------------------------------------------------

  it "raises current_skill_level to effective_cap on :current side" do
    turbo_post max_skills_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 3, @cs1.reload.current_skill_level
  end

  it "does not touch target when maxing current side (spec 03 R2)" do
    turbo_post max_skills_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 1, @cs1.reload.target_skill_level
  end

  it "raises target_skill_level to effective_cap on :target side" do
    turbo_post max_skills_character_path(@char),
               { side: :target, mastery_id: @mastery1.id }
    assert_equal 3, @cs1.reload.target_skill_level
  end

  it "does not touch other mastery skills on max_skills (spec 06 R3)" do
    turbo_post max_skills_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 1, @cs3.reload.current_skill_level
  end

  it "returns turbo_stream with mastery-header on max_skills success" do
    turbo_post max_skills_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_response :success
    assert_equal TURBO_STREAM, response.media_type
    assert_includes response.body, "mastery-header"
  end

  it "returns skill row ids in turbo_stream on max_skills success" do
    turbo_post max_skills_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_includes response.body, "skill-row-#{@sg1.id}"
  end

  it "returns 422 for invalid side on max_skills" do
    turbo_post max_skills_character_path(@char),
               { side: :bad, mastery_id: @mastery1.id }
    assert_response :unprocessable_entity
  end

  # ---- clear_mastery auth ------------------------------------------------------

  it "redirects unauthenticated clear_mastery to login" do
    sign_out
    turbo_post clear_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_redirected_to new_session_path
  end

  it "returns 404 for another user's character on clear_mastery" do
    turbo_post clear_mastery_character_path(@other_char),
               { side: :current, mastery_id: @mastery1.id }
    assert_response :not_found
  end

  # ---- clear_mastery behavior --------------------------------------------------

  it "zeroes current_skill_level on :current side" do
    turbo_post clear_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 0, @cs1.reload.current_skill_level
  end

  it "zeroes current_mastery_level on :current side" do
    turbo_post clear_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 0, @cm1.reload.current_mastery_level
  end

  it "does not touch target when clearing current side (spec 03 R2)" do
    turbo_post clear_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 1, @cs1.reload.target_skill_level
    assert_equal 50, @cm1.reload.target_mastery_level
  end

  it "does not touch other mastery on clear_mastery (spec 06 R3)" do
    turbo_post clear_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 1, @cs3.reload.current_skill_level
    assert_equal 50, @cm2.reload.current_mastery_level
  end

  it "returns turbo_stream with mastery-header on clear_mastery success" do
    turbo_post clear_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_response :success
    assert_equal TURBO_STREAM, response.media_type
    assert_includes response.body, "mastery-header"
  end

  it "returns 422 for invalid side on clear_mastery" do
    turbo_post clear_mastery_character_path(@char),
               { side: :bad, mastery_id: @mastery1.id }
    assert_response :unprocessable_entity
  end

  # ---- max_mastery auth -------------------------------------------------------

  it "redirects unauthenticated max_mastery to login" do
    sign_out
    turbo_post max_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_redirected_to new_session_path
  end

  it "returns 404 for another user's character on max_mastery" do
    turbo_post max_mastery_character_path(@other_char),
               { side: :current, mastery_id: @mastery1.id }
    assert_response :not_found
  end

  # ---- max_mastery behavior ---------------------------------------------------

  it "sets current_mastery_level to cap on :current side" do
    turbo_post max_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 110, @cm1.reload.current_mastery_level
  end

  it "does not touch target when maxing current side" do
    turbo_post max_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 50, @cm1.reload.target_mastery_level
  end

  it "sets target_mastery_level to cap on :target side" do
    turbo_post max_mastery_character_path(@char),
               { side: :target, mastery_id: @mastery1.id }
    assert_equal 110, @cm1.reload.target_mastery_level
  end

  it "does not touch other mastery on max_mastery" do
    turbo_post max_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_equal 50, @cm2.reload.current_mastery_level
  end

  it "returns turbo_stream with mastery-header on max_mastery success" do
    turbo_post max_mastery_character_path(@char),
               { side: :current, mastery_id: @mastery1.id }
    assert_response :success
    assert_equal TURBO_STREAM, response.media_type
    assert_includes response.body, "mastery-header"
  end

  it "returns 422 for invalid side on max_mastery" do
    turbo_post max_mastery_character_path(@char),
               { side: :bad, mastery_id: @mastery1.id }
    assert_response :unprocessable_entity
  end
end
