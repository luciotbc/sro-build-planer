require "test_helper"

class CreateCharacterTest < ActionView::TestCase
  include Rails.application.routes.url_helpers

  before do
    @chinese = races(:chinese)
    @european = races(:european)
  end

  describe "shared/chinese_glyph partial" do
    it "renders the Chinese glyph character" do
      render partial: "shared/chinese_glyph"
      assert_select "[data-race='chinese']"
    end

    it "contains the Chinese glyph" do
      render partial: "shared/chinese_glyph"
      assert_match "华", rendered
    end
  end

  describe "shared/european_glyph partial" do
    it "renders the European glyph element" do
      render partial: "shared/european_glyph"
      assert_select "[data-race='european']"
    end

    it "contains the European glyph" do
      render partial: "shared/european_glyph"
      assert_match "⚔", rendered
    end
  end

  describe "shared/create_character partial" do
    it "renders a dialog element" do
      render partial: "shared/create_character"
      assert_select "dialog"
    end

    it "renders a form pointing to characters_path" do
      render partial: "shared/create_character"
      assert_select "form[action=?]", characters_path
    end

    it "renders a name input" do
      render partial: "shared/create_character"
      assert_select "input[name='character[name]']"
    end

    it "renders both race radio inputs" do
      render partial: "shared/create_character"
      assert_select "input[type='radio'][name='character[race_id]']", count: 2
    end

    it "renders level cap as radio buttons" do
      render partial: "shared/create_character"
      assert_select "input[type='radio'][name='character[server_level_cap]']",
                    count: 5
    end

    it "defaults the cap selector to 110" do
      render partial: "shared/create_character"
      assert_select "input[type='radio'][name='character[server_level_cap]'][value='110'][checked]"
    end

    it "renders all five cap radio inputs" do
      render partial: "shared/create_character"
      [90, 100, 110, 120, 130].each do |cap|
        assert_select "input[type='radio'][name='character[server_level_cap]'][value='#{cap}']"
      end
    end

    it "renders a submit button labeled 'Start Build'" do
      render partial: "shared/create_character"
      assert_select "input[type='submit'][value='Start Build'],button[type='submit']",
                    text: /Start Build/
    end
  end
end
