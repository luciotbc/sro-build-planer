require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @other_user = create(:user)
    @race = create(:race)
    @other_race = create(:race)
    @char = create(:character, user: @user, race: @race, name: "Blade Lord")
    @other_char =
      create(:character, user: @other_user, race: @race, name: "Other's Char")
  end

  # ---- auth-required on all actions -----------------------------------------

  it "redirects unauthenticated requests to login" do
    get characters_path
    assert_redirected_to new_session_path
  end

  it "redirects unauthenticated create to login" do
    post characters_path,
         params: {
           character: {
             name: "Test",
             race_id: @race.id
           }
         }
    assert_redirected_to new_session_path
  end

  # ---- index ----------------------------------------------------------------

  it "redirects GET /characters to root" do
    sign_in_as @user
    get characters_path
    assert_redirected_to root_path
  end

  # ---- create ---------------------------------------------------------------

  it "creates a character and redirects on success" do
    sign_in_as @user
    assert_difference "Character.count" do
      post characters_path,
           params: {
             character: {
               name: "New Hero",
               race_id: @race.id,
               server_level_cap: 110
             }
           }
    end
    assert_redirected_to character_path(Character.last)
  end

  it "does not create and redirects to root on invalid params" do
    sign_in_as @user
    assert_no_difference "Character.count" do
      post characters_path,
           params: {
             character: {
               name: "",
               race_id: @race.id
             }
           }
    end
    assert_redirected_to root_path
  end

  # ---- show -----------------------------------------------------------------

  it "shows the character when owner" do
    sign_in_as @user
    get character_path(@char)
    assert_response :success
  end

  it "returns 404 when accessing another user's character" do
    sign_in_as @user
    get character_path(@other_char)
    assert_response :not_found
  end

  # ---- update ---------------------------------------------------------------

  it "updates character name and redirects" do
    sign_in_as @user
    patch character_path(@char), params: { character: { name: "Renamed Hero" } }
    assert_redirected_to character_path(@char)
    assert_equal "Renamed Hero", @char.reload.name
  end

  it "redirects with alert on service failure (server_level_cap below mastery)" do
    mastery = create(:mastery, race: @race)
    create(
      :character_mastery,
      character: @char,
      mastery:,
      current_mastery_level: 100,
      target_mastery_level: 100
    )
    sign_in_as @user
    original_cap = @char.server_level_cap
    patch character_path(@char), params: { character: { server_level_cap: 90 } }
    assert_redirected_to character_path(@char)
    assert flash[:alert].present?
    assert_equal original_cap, @char.reload.server_level_cap
  end

  it "updates server_level_cap and redirects" do
    sign_in_as @user
    patch character_path(@char),
          params: {
            character: {
              server_level_cap: 120
            }
          }
    assert_redirected_to character_path(@char)
    assert_equal 120, @char.reload.server_level_cap
  end

  it "returns 404 when updating another user's character" do
    sign_in_as @user
    patch character_path(@other_char),
          params: {
            character: {
              name: "Hijacked"
            }
          }
    assert_response :not_found
  end

  # ---- destroy --------------------------------------------------------------

  it "deletes the character and redirects to index" do
    sign_in_as @user
    assert_difference "Character.count", -1 do
      delete character_path(@char)
    end
    assert_redirected_to characters_path
  end

  it "returns 404 when deleting another user's character" do
    sign_in_as @user
    delete character_path(@other_char)
    assert_response :not_found
  end
end
