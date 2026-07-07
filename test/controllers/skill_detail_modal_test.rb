require "test_helper"

# Task 014 — skill & series detail modals (docs/todo/014-skill-info-panel.md,
# specs 02 sp_cost / 04 mastery_level_req). The modals are presentational
# partials rendered from the editor and the character show page.
class SkillDetailModalTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = create(:race)
    @mastery =
      create(:mastery, race: @race, name: "Blade", mastery_type: "Weapon")
    @series = create(:skill_series, mastery: @mastery, title: "Basic")
    @prereq_group =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Stance",
        max_skill_level: 5
      )
    @sg =
      create(
        :skill_group,
        mastery: @mastery,
        skill_series: @series,
        name: "Slash",
        max_skill_level: 3,
        description: "A focused thrust dealing physical damage."
      )
    create(
      :skill_group_requirement,
      skill_group: @sg,
      required_group: @prereq_group
    )
    @skill1 =
      create(
        :skill,
        skill_group: @sg,
        skill_level: 1,
        sp_cost: 100,
        mastery_level_req: 4
      )
    @skill2 =
      create(
        :skill,
        skill_group: @sg,
        skill_level: 2,
        sp_cost: 3240,
        mastery_level_req: 8
      )
    create(
      :skill,
      skill_group: @prereq_group,
      skill_level: 1,
      sp_cost: 50,
      mastery_level_req: 1
    )

    @char = create(:character, user: @user, race: @race, server_level_cap: 110)
    create(
      :character_mastery,
      character: @char,
      mastery: @mastery,
      current_mastery_level: 10,
      target_mastery_level: 20
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

  describe "skill detail modal partial" do
    it "renders name, level, required mastery, next-level SP cost and description" do
      html =
        ApplicationController.render(
          partial: "skills/skill_detail_modal",
          locals: {
            skill: @skill1
          }
        )

      assert_includes html, "Slash"
      assert_includes html, "overlay-head"
      # Level 1 / 3
      assert_match %r{>\s*1\s*</span>\s*<[^>]+>\s*/\s*3}m, html
      assert_includes html, "Lv 4" # mastery_level_req of the shown level
      assert_includes html, "3,240" # sp_cost of level 2 (next level)
      assert_includes html, "A focused thrust dealing physical damage."
    end

    it "renders a footer close button" do
      html =
        ApplicationController.render(
          partial: "skills/skill_detail_modal",
          locals: {
            skill: @skill1
          }
        )

      assert_match /btn-primary[^>]*data-action="dialog#close"/, html

      series_html =
        ApplicationController.render(
          partial: "skills/skill_series_detail_modal",
          locals: {
            skill_series: @series
          }
        )
      assert_match /btn-primary[^>]*data-action="dialog#close"/, series_html
    end

    it "lists prerequisite skill groups in a table" do
      html =
        ApplicationController.render(
          partial: "skills/skill_detail_modal",
          locals: {
            skill: @skill1
          }
        )

      assert_includes html, "Stance"
      assert_includes html, "<table"
    end

    it "shows N/A for SP cost at max level and omits blank rows" do
      html =
        ApplicationController.render(
          partial: "skills/skill_detail_modal",
          locals: {
            skill: @skill2
          }
        )

      assert_includes html, "N/A" # no level-3 variant exists

      bare =
        ApplicationController.render(
          partial: "skills/skill_detail_modal",
          locals: {
            skill:
              create(
                :skill,
                skill_group:
                  create(:skill_group, mastery: @mastery, name: "Bare"),
                skill_level: 1,
                mastery_level_req: nil,
                sp_cost: nil
              )
          }
        )
      refute_includes bare, "Required Mastery"
      refute_includes bare, "<table"
    end
  end

  describe "series detail modal partial" do
    it "renders series title and contained skill groups" do
      html =
        ApplicationController.render(
          partial: "skills/skill_series_detail_modal",
          locals: {
            skill_series: @series
          }
        )

      assert_includes html, "Basic"
      assert_includes html, "overlay-head"
      assert_includes html, "Slash"
      assert_includes html, "Stance"
    end
  end

  describe "editor trigger" do
    it "embeds the skill detail modal on the editor page" do
      get edit_character_path(@char)
      assert_response :success
      assert_select "dialog.modal .overlay-head", text: /Slash/
      assert_select "[data-action*='dialog#open']"
    end

    it "opens the modal from the skill name as well as the icon" do
      get edit_character_path(@char)
      assert_response :success
      assert_select "button.fs-skill-name[data-action*='dialog#open']",
                    text: /Slash/
    end

    it "opens the series detail modal from the series header icon/title" do
      get edit_character_path(@char)
      assert_response :success
      # trigger: icon + title button
      assert_select "button[data-action*='dialog#open'] .series-badge"
      # its dialog carries the series title and contained skills
      assert_select "dialog.modal .overlay-head", text: /Basic/
      # collapse toggle still present alongside the trigger
      assert_select "[data-action*='collapsible#toggle']"
    end
  end

  describe "character show trigger" do
    it "embeds the skill detail modal on the show page" do
      get character_path(@char, mastery_id: @mastery.id)
      follow_redirect! while response.redirect?
      assert_response :success
      assert_select "dialog.modal .overlay-head", text: /Slash/
    end
  end
end
