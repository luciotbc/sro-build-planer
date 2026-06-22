require "test_helper"

# Verifies that service warnings are surfaced as toasts in Turbo Stream responses.
# Spec 03 R3-R5: prerequisite_added, character_mastery_level_updated, skill_level_adjusted.
class PrerequisiteFeedbackTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = "text/vnd.turbo-stream.html"

  before do
    @user = create(:user)
    @race = races(:chinese)
    @mastery =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series = create(:skill_series, mastery: @mastery, title: "Basic")

    @sg_pre =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Guard",
        max_skill_level: 1
      )
    create(:skill, skill_group: @sg_pre, skill_level: 1, mastery_level_req: 1)

    @sg_dep =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Slash",
        max_skill_level: 2
      )
    create(:skill, skill_group: @sg_dep, skill_level: 1, mastery_level_req: 1)
    create(:skill, skill_group: @sg_dep, skill_level: 2, mastery_level_req: 5)
    create(
      :skill_group_requirement,
      skill_group: @sg_dep,
      required_group: @sg_pre,
      required_skill_level: 1
    )

    @char =
      create(
        :character,
        user: @user,
        race: @race,
        server_level_cap: 110,
        current_level: 10,
        target_level: 10
      )
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery,
      current_mastery_level: 10,
      target_mastery_level: 10
    )

    sign_in_as @user
  end

  # ---- CharacterSkillsController: prerequisite auto-add warning ---------------

  it "includes toast markup when a prerequisite is auto-added" do
    # Adding sg_dep level 1 without sg_pre -> AddService auto-adds sg_pre, emits warning
    patch character_character_skill_path(@char, @sg_dep),
          params: {
            side: :current,
            level: 1
          },
          headers: {
            "Accept" => TURBO_STREAM
          }
    assert_response :success
    assert_includes response.body, "data-controller=\"toast\""
  end

  it "includes I18n prerequisite_added text in toast when prerequisite auto-added" do
    patch character_character_skill_path(@char, @sg_dep),
          params: {
            side: :current,
            level: 1
          },
          headers: {
            "Accept" => TURBO_STREAM
          }
    expected =
      CGI.escapeHTML(I18n.t("warnings.prerequisite_added", name: @sg_pre.name))
    assert_includes response.body, expected
  end

  it "includes toast-container append in turbo stream" do
    patch character_character_skill_path(@char, @sg_dep),
          params: {
            side: :current,
            level: 1
          },
          headers: {
            "Accept" => TURBO_STREAM
          }
    assert_includes response.body, "toast-container"
  end

  # ---- CharacterMasteriesController: skill downgrade warning ------------------

  it "includes toast when mastery decrease auto-downgrades a skill" do
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_dep,
      current_skill_level: 2,
      target_skill_level: 2
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_pre,
      current_skill_level: 1,
      target_skill_level: 1
    )
    # Drop mastery from 10 to 3 -> sg_dep level 2 (req=5) > 3 -> downgraded to level 1
    patch character_character_mastery_path(@char, @mastery),
          params: {
            side: :current,
            level: 3
          },
          headers: {
            "Accept" => TURBO_STREAM
          }
    assert_includes response.body, "data-controller=\"toast\""
  end

  it "includes I18n skill_level_adjusted text in toast on mastery decrease" do
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_dep,
      current_skill_level: 2,
      target_skill_level: 2
    )
    create(
      :character_skill,
      character: @char,
      skill_group: @sg_pre,
      current_skill_level: 1,
      target_skill_level: 1
    )
    patch character_character_mastery_path(@char, @mastery),
          params: {
            side: :current,
            level: 3
          },
          headers: {
            "Accept" => TURBO_STREAM
          }
    expected =
      CGI.escapeHTML(
        I18n.t(
          "warnings.skill_level_adjusted",
          name: @sg_dep.name,
          attr: :current_skill_level,
          level: 1
        )
      )
    assert_includes response.body, expected
  end

  # ---- BulkSkillActionsController: prerequisite auto-add warning from max -----

  it "includes toast when max_skills auto-adds a prerequisite" do
    # No skills allocated; maxing sg_dep auto-adds sg_pre (prerequisite)
    post max_skills_character_path(@char),
         params: {
           side: :current,
           mastery_id: @mastery.id
         },
         headers: {
           "Accept" => TURBO_STREAM
         }
    assert_includes response.body, "data-controller=\"toast\""
  end

  # ---- Layout: toast container present ----------------------------------------

  it "layout includes toast-container" do
    get edit_character_path(@char)
    assert_select "#toast-container"
  end
end
