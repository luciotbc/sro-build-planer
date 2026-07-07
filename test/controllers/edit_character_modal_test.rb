require "test_helper"

# Task 020 — "Edit character" modal on the planner show screen (spec 05 R3/R4).
class EditCharacterModalTest < ActionDispatch::IntegrationTest
  before do
    @user = create(:user)
    @race = create(:race)
    @char =
      create(
        :character,
        user: @user,
        race: @race,
        name: "Blade Lord",
        server_level_cap: 110
      )
    sign_in_as @user
  end

  it "renders the hover pencil edit trigger in the char bar" do
    get character_path(@char)
    assert_response :success
    assert_select ".char-bar [data-action='dialog#open']"
  end

  it "renders the edit modal with prefilled name and current cap selected" do
    get character_path(@char)
    assert_select "dialog form[action=?]", character_path(@char) do
      assert_select "input[name='_method'][value='patch']", 1
      assert_select "input[name='character[name]'][value='Blade Lord']", 1
      assert_select "input[name='character[server_level_cap]'][value='110'][checked]",
                    1
    end
  end

  it "omits the race selector from the edit modal" do
    get character_path(@char)
    assert_select "dialog form[action=?]", character_path(@char) do
      assert_select "input[name='character[race_id]']", 0
    end
  end

  it "labels the modal 'Edit character' with a 'Save' submit" do
    get character_path(@char)
    assert_match "Edit character", response.body
    assert_select "dialog form[action=?]", character_path(@char) do
      assert_select "button[type='submit']", text: "Save"
    end
  end
end
