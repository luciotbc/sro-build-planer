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

    it "renders 'Your characters' as the header title" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_match /Your characters/i, rendered
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

    it "renders a 'New Character' link" do
      render partial: "shared/chars_drawer", locals: { characters: @characters }
      assert_select "a[href=?]", new_character_path
    end

    it "shows an empty state message when no characters" do
      render partial: "shared/chars_drawer", locals: { characters: [] }
      assert_match /no character/i, rendered
    end
  end
end
