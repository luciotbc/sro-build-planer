require "test_helper"

# Integration tests covering empty/landing states (task 015).
class EmptyStatesTest < ActionDispatch::IntegrationTest
  # ---- home / landing ----------------------------------------------------------

  it "unauthenticated user sees landing page with Log in link" do
    get root_path
    assert_response :success
    assert_select "a[href='#{new_session_path}']", minimum: 1
  end

  it "unauthenticated user sees Register link on landing page" do
    get root_path
    assert_response :success
    assert_select "a[href='#{new_registration_path}']", minimum: 1
  end

  it "authenticated user is redirected from home to characters index" do
    sign_in_as create(:user)
    get root_path
    assert_redirected_to characters_path
  end

  # ---- characters index empty state -------------------------------------------

  it "characters index shows empty state when user has no characters" do
    sign_in_as create(:user)
    get characters_path
    assert_response :success
    assert_includes response.body, "No characters yet"
  end

  it "characters index empty state links to new character" do
    sign_in_as create(:user)
    get characters_path
    assert_select "a[href='#{new_character_path}']", minimum: 1
  end

  # ---- characters edit empty mastery ------------------------------------------

  it "edit view shows message when no mastery selected" do
    user = create(:user)
    char = create(:character, user: user, race: races(:chinese))
    sign_in_as user
    get edit_character_path(char, side: :current)
    assert_response :success
    assert_includes response.body, "No mastery available"
  end

  # ---- stepper aria-busy loading attribute -------------------------------------

  it "stepper row has data-controller stepper for loading state wire-up" do
    user = create(:user)
    mastery =
      create(
        :mastery,
        race: races(:chinese),
        name: "Blade",
        mastery_type: "Weapon"
      )
    series = create(:skill_series, mastery: mastery)
    sg =
      create(
        :skill_group,
        mastery: mastery,
        skill_series: series,
        max_skill_level: 3
      )
    create(:skill, skill_group: sg, skill_level: 1, mastery_level_req: 1)
    char =
      create(
        :character,
        user: user,
        race: races(:chinese),
        server_level_cap: 110,
        current_level: 5,
        target_level: 5
      )
    create(:character_mastery, character: char, mastery: mastery)
    sign_in_as user
    get edit_character_path(char, side: :current, mastery_id: mastery.id)
    assert_response :success
    assert_select "[data-controller~='stepper']", minimum: 1
  end
end
