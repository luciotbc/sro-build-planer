require "test_helper"

class CharacterSkillsControllerTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = "text/vnd.turbo-stream.html"

  before do
    @user = create(:user)
    @other_user = create(:user)
    @race = races(:chinese)

    @mastery =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series = create(:skill_series, mastery: @mastery, title: "Basic")

    # sg1: 3 levels, skills at mastery req 1 and 5
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

    # sg2: requires sg1 at level 1 (for cascade test)
    @sg2 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Cut",
        max_skill_level: 5
      )
    create(:skill, skill_group: @sg2, skill_level: 1, mastery_level_req: 1)
    create(
      :skill_group_requirement,
      skill_group: @sg2,
      required_group: @sg1,
      required_skill_level: 1
    )

    @char =
      create(
        :character,
        user: @user,
        race: @race,
        server_level_cap: 110,
        current_level: 5,
        target_level: 5
      )
    @cm =
      create(
        :character_mastery,
        character: @char,
        mastery: @mastery,
        current_mastery_level: 5,
        target_mastery_level: 5
      )

    # Allocated character skills
    @cs1 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg1,
        current_skill_level: 1,
        target_skill_level: 1
      )

    @other_char = create(:character, user: @other_user, race: @race)

    sign_in_as @user
  end

  def turbo_patch(character, skill_group, params)
    patch character_character_skill_path(character, skill_group),
          params: params,
          headers: {
            "Accept" => TURBO_STREAM
          }
  end

  # ---- auth -------------------------------------------------------------------

  it "redirects unauthenticated requests to login" do
    sign_out
    turbo_patch @char, @sg1, { side: :current, level: 2 }
    assert_redirected_to new_session_path
  end

  it "returns 404 when updating another user's character" do
    turbo_patch @other_char, @sg1, { side: :current, level: 1 }
    assert_response :not_found
  end

  # ---- current side increment -------------------------------------------------

  it "increments current_skill_level on :current side" do
    turbo_patch @char, @sg1, { side: :current, level: 2 }
    assert_equal 2, @cs1.reload.current_skill_level
  end

  it "responds with turbo_stream on success" do
    turbo_patch @char, @sg1, { side: :current, level: 2 }
    assert_response :success
    assert_equal TURBO_STREAM, response.media_type
    assert_includes response.body, "turbo-stream"
  end

  it "replaces the correct skill row in the turbo stream" do
    turbo_patch @char, @sg1, { side: :current, level: 2 }
    assert_includes response.body, "skill-row-#{@sg1.id}"
  end

  # ---- mastery header refresh (slider + skills count) -------------------------

  it "replaces the mastery header on every successful skill edit" do
    turbo_patch @char, @sg1, { side: :current, level: 2 }
    assert_response :success
    assert_includes response.body, 'target="mastery-header"'
  end

  it "reflects the raised mastery level in the header after a skill bump" do
    # sg1 level 3 requires mastery level 10; @cm starts at 5 -> auto-bumped to 10
    turbo_patch @char, @sg1, { side: :current, level: 3 }
    assert_response :success
    assert_equal 10, @cm.reload.current_mastery_level
    assert_includes response.body, 'target="mastery-header"'
    assert_includes response.body, 'data-stepper-level-value="10"'
  end

  # ---- target side increment --------------------------------------------------

  it "increments target_skill_level on :target side" do
    turbo_patch @char, @sg1, { side: :target, level: 2 }
    assert_equal 2, @cs1.reload.target_skill_level
  end

  it "does not touch current_skill_level when editing target side" do
    turbo_patch @char, @sg1, { side: :target, level: 2 }
    assert_equal 1, @cs1.reload.current_skill_level
  end

  it "does not touch target_skill_level when editing current side" do
    turbo_patch @char, @sg1, { side: :current, level: 2 }
    assert_equal 1, @cs1.reload.target_skill_level
  end

  # ---- cascade ----------------------------------------------------------------

  it "auto-adds prerequisite CharacterSkill on correct side when incrementing" do
    # sg2 requires sg1 at level 1; @char has no cs for sg2
    # Incrementing sg2 current to 1 should cascade-create cs1 (already satisfied)
    # and create cs2
    assert_difference "CharacterSkill.count", 1 do
      turbo_patch @char, @sg2, { side: :current, level: 1 }
    end
    assert_response :success
    cs2 = CharacterSkill.find_by(character: @char, skill_group: @sg2)
    assert_not_nil cs2
    assert_equal 1, cs2.current_skill_level
  end

  it "streams the auto-bumped prerequisite row so the UI stays in sync" do
    # sg3 requires sg1 at level 2; cs1 sits at 1, so bumping sg3 cascades
    # cs1 to 2 — the response must replace sg1's row with the new level.
    sg3 =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Heavy Cut",
        max_skill_level: 5
      )
    create(:skill, skill_group: sg3, skill_level: 1, mastery_level_req: 1)
    create(
      :skill_group_requirement,
      skill_group: sg3,
      required_group: @sg1,
      required_skill_level: 2
    )

    turbo_patch @char, sg3, { side: :current, level: 1 }
    assert_response :success
    assert_equal 2, @cs1.reload.current_skill_level
    assert_includes response.body, "skill-row-#{@sg1.id}"
    row =
      response.body[
        %r{<turbo-stream[^>]*target="skill-row-#{@sg1.id}".*?</turbo-stream>}m
      ]
    assert_not_nil row
    assert_includes row, 'data-stepper-level-value="2"'
  end

  # ---- decrement blocked by dependent -----------------------------------------

  it "returns 422 when decrement is blocked by a dependent" do
    # cs2 depends on cs1 at level >= 1 (current side)
    cs2 =
      create(
        :character_skill,
        character: @char,
        skill_group: @sg2,
        current_skill_level: 1,
        target_skill_level: 0
      )
    turbo_patch @char, @sg1, { side: :current, level: 0 }
    assert_response :unprocessable_entity
    assert_equal TURBO_STREAM, response.media_type
    assert_equal 1, @cs1.reload.current_skill_level
  end

  it "includes an error turbo-stream action in blocked response" do
    create(
      :character_skill,
      character: @char,
      skill_group: @sg2,
      current_skill_level: 1,
      target_skill_level: 0
    )
    turbo_patch @char, @sg1, { side: :current, level: 0 }
    assert_includes response.body, "turbo-stream"
    assert_includes response.body, "skill-editor-error"
  end

  # ---- create via AddService when CharacterSkill does not exist ---------------

  it "creates a CharacterSkill when one does not exist yet and level > 0" do
    # @char has no cs for @sg2
    assert_difference "CharacterSkill.count", 1 do
      turbo_patch @char, @sg2, { side: :target, level: 1 }
    end
    cs2 = CharacterSkill.find_by(character: @char, skill_group: @sg2)
    assert_not_nil cs2
    assert_equal 1, cs2.target_skill_level
    assert_equal 0, cs2.current_skill_level
  end

  it "is a no-op when CharacterSkill does not exist and level is 0" do
    assert_no_difference "CharacterSkill.count" do
      turbo_patch @char, @sg2, { side: :current, level: 0 }
    end
    assert_response :success
  end

  # ---- invalid side param -----------------------------------------------------

  it "returns 422 for an invalid side param" do
    turbo_patch @char, @sg1, { side: :bad, level: 2 }
    assert_response :unprocessable_entity
  end
end
