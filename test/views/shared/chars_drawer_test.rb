require "test_helper"

class CharsDrawerTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  before do
    @race = races(:chinese)
    @user = create(:user)
    @char1 = create(:character, user: @user, race: @race, name: "Blade Lord")
    @char2 = create(:character, user: @user, race: @race, name: "Cold Mage")
    @characters = [@char1, @char2]
  end

  describe "shared/chars_drawer partial" do
    it "renders a drawer dialog element" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select "dialog.drawer"
    end

    it "renders 'characters' as the header title" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select ".overlay-head span", text: "Characters"
    end

    it "lists each character by name" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_match "Blade Lord", rendered
      assert_match "Cold Mage", rendered
    end

    it "links each character to its character path" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select "a[href=?]", character_path(@char1)
      assert_select "a[href=?]", character_path(@char2)
    end

    it "renders a trigger with the character count" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select ".chars-pill .count", text: "2"
    end

    it "renders a '+ New character' modal trigger button" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select "button[data-action='dialog#open']", text: /New character/
    end

    it "shows an empty state message when no characters" do
      render partial: "shared/chars_drawer", locals: { characters: [] }
      assert_match /no character/i, rendered
    end

    it "shows ACTIVE badge for the active character" do
      render partial: "shared/chars_drawer",
             locals: {
               characters: @characters,
               active_character_id: @char1.id
             }
      assert_select "[data-active-badge]", text: "ACTIVE"
    end

    it "does not show ACTIVE badge when no active_character_id given" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select "[data-active-badge]", count: 0
    end

    it "highlights the active character row" do
      render partial: "shared/chars_drawer",
             locals: {
               characters: @characters,
               active_character_id: @char1.id
             }
      assert_select "a[data-active-row]"
    end
  end
end
