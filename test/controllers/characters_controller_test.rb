require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = create(:race, :chinese)
    @character = create(:character, user: @user, race: @race, name: "BuckTBC")
  end

  describe "authentication" do
    it "redirects guests to login on index" do
      get characters_path

      assert_redirected_to new_session_path
    end

    it "redirects guests to login on create" do
      post characters_path, params: { character: { name: "X" } }

      assert_redirected_to new_session_path
    end
  end

  describe "GET /characters" do
    before { sign_in_as(@user) }

    it "lists only the current user's characters" do
      other = create(:character, name: "NotMine", race: @race)

      get characters_path

      assert_response :success
      assert_match "BuckTBC", response.body
      assert_no_match other.name, response.body
    end

    it "renders inside the modal turbo frame" do
      get characters_path

      assert_select "turbo-frame#modal"
    end

    it "loads characters without N+1 queries" do
      create_list(:character, 3, user: @user, race: @race)

      query_count = 0
      counter = ->(_name, _start, _finish, _id, payload) do
        query_count += 1 unless payload[:name] == "SCHEMA"
      end
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get characters_path
      end

      assert_operator query_count,
                      :<=,
                      10,
                      "Expected at most 10 queries but got #{query_count}"
      assert_response :success
    end
  end

  describe "GET /characters/new" do
    before { sign_in_as(@user) }

    it "renders the create character form with races and level caps" do
      create(:race, :european)

      get new_character_path

      assert_response :success
      assert_select "form[action=?]", characters_path
      assert_match "Chinese", response.body
      assert_match "European", response.body
      assert_match "110", response.body
    end
  end

  describe "POST /characters" do
    before { sign_in_as(@user) }

    it "creates a character for the current user and selects it" do
      assert_difference -> { @user.characters.count }, 1 do
        post characters_path,
             params: {
               character: {
                 name: "Glaiver",
                 race_id: @race.id,
                 target_level: 110
               }
             }
      end

      character = @user.characters.order(:id).last

      assert_equal "Glaiver", character.name
      assert_equal 110, character.target_level
      assert_redirected_to root_path
    end

    it "rejects invalid params" do
      assert_no_difference -> { Character.count } do
        post characters_path,
             params: {
               character: {
                 name: "",
                 race_id: @race.id,
                 target_level: 110
               }
             }
      end

      assert_response :unprocessable_entity
    end

    it "rejects a forged target_level not in LEVEL_CAPS" do
      assert_no_difference -> { Character.count } do
        post characters_path,
             params: {
               character: {
                 name: "Hacker",
                 race_id: @race.id,
                 target_level: 150
               }
             }
      end

      assert_response :unprocessable_entity
    end
  end

  describe "POST /characters/:id/select" do
    before { sign_in_as(@user) }

    it "marks the character as active and redirects home" do
      other = create(:character, user: @user, race: @race, name: "Second")

      post select_character_path(other)

      assert_redirected_to root_path

      get root_path

      assert_match "Second", response.body
    end

    it "does not select another user's character" do
      foreign = create(:character, race: @race)

      post select_character_path(foreign)

      assert_response :not_found
    end
  end
end
