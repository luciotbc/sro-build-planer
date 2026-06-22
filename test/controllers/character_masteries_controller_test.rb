require "test_helper"

class CharacterMasteriesControllerTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = "text/vnd.turbo-stream.html"

  before do
    @user = create(:user)
    @other_user = create(:user)
    @race = races(:chinese)

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
    create(:skill, skill_group: @sg1, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sg1, skill_level: 2, mastery_level_req: 5)
    create(:skill, skill_group: @sg1, skill_level: 3, mastery_level_req: 10)

    @char =
      create(
        :character,
        user: @user,
        race: @race,
        server_level_cap: 110,
        current_level: 10,
        target_level: 10
      )
    @cm =
      create(
        :character_mastery,
        character: @char,
        mastery: @mastery,
        current_mastery_level: 10,
        target_mastery_level: 10
      )
    @cs1 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 2,
        target_skill_level: 2
      )

    @other_char = create(:character, user: @other_user, race: @race)

    sign_in_as @user
  end

  def turbo_patch(character, mastery, params)
    patch character_character_mastery_path(character, mastery),
          params: params,
          headers: {
            "Accept" => TURBO_STREAM
          }
  end

  # ---- auth -------------------------------------------------------------------

  it "redirects unauthenticated requests to login" do
    sign_out
    turbo_patch @char, @mastery, { side: :current, level: 5 }
    assert_redirected_to new_session_path
  end

  it "returns 404 for another user's character" do
    turbo_patch @other_char, @mastery, { side: :current, level: 5 }
    assert_response :not_found
  end

  # ---- current side -----------------------------------------------------------

  it "raises current_mastery_level on :current side" do
    turbo_patch @char, @mastery, { side: :current, level: 20 }
    assert_equal 20, @cm.reload.current_mastery_level
  end

  it "responds with turbo_stream on success" do
    turbo_patch @char, @mastery, { side: :current, level: 20 }
    assert_response :success
    assert_equal TURBO_STREAM, response.media_type
    assert_includes response.body, "turbo-stream"
  end

  it "replaces mastery-header in turbo stream" do
    turbo_patch @char, @mastery, { side: :current, level: 20 }
    assert_includes response.body, "mastery-header"
  end

  it "replaces skill rows in turbo stream" do
    turbo_patch @char, @mastery, { side: :current, level: 20 }
    assert_includes response.body, "skill-row-#{@sg1.id}"
  end

  # ---- target side independence -----------------------------------------------

  it "raises target_mastery_level on :target side" do
    turbo_patch @char, @mastery, { side: :target, level: 30 }
    assert_equal 30, @cm.reload.target_mastery_level
  end

  it "does not touch current_mastery_level when editing target side" do
    turbo_patch @char, @mastery, { side: :target, level: 30 }
    assert_equal 10, @cm.reload.current_mastery_level
  end

  # ---- auto-downgrade on decrease (spec 03 R7) --------------------------------

  it "auto-downgrades skills when mastery level decreases below mastery_level_req" do
    # @cs1 current_skill_level=2, skill at level 2 has mastery_level_req=5
    # Dropping mastery to 3 → skill 2 unreachable → downgraded to level 1
    turbo_patch @char, @mastery, { side: :current, level: 3 }
    assert_equal 1, @cs1.reload.current_skill_level
  end

  it "does not touch target skill when decreasing current mastery (spec 03 R2)" do
    turbo_patch @char, @mastery, { side: :current, level: 3 }
    assert_equal 2, @cs1.reload.target_skill_level
  end

  it "returns success even when skills are auto-downgraded" do
    turbo_patch @char, @mastery, { side: :current, level: 3 }
    assert_response :success
  end

  # ---- above server_level_cap -------------------------------------------------

  it "returns 422 when level exceeds server_level_cap" do
    turbo_patch @char, @mastery, { side: :current, level: 200 }
    assert_response :unprocessable_entity
    assert_equal TURBO_STREAM, response.media_type
    assert_includes response.body, "skill-editor-error"
  end

  it "does not update mastery when level exceeds server_level_cap" do
    turbo_patch @char, @mastery, { side: :current, level: 200 }
    assert_equal 10, @cm.reload.current_mastery_level
  end

  # ---- invalid side -----------------------------------------------------------

  it "returns 422 for invalid side param" do
    turbo_patch @char, @mastery, { side: :bad, level: 20 }
    assert_response :unprocessable_entity
  end
end
