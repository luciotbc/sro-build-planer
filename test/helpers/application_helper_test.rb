require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  describe "#game_icon_tag" do
    # A real bundled asset (see app/assets/images/skill/china/).
    BUNDLED_ICON = "skill/china/sword_smash_a.png".freeze

    it "renders an img for a bundled icon_path" do
      html = game_icon_tag(BUNDLED_ICON, alt: "")
      assert_match(/<img/, html)
      assert_match(/sword_smash_a/, html)
    end

    it "passes html options through to image_tag" do
      html = game_icon_tag(BUNDLED_ICON, alt: "", class: "x")
      assert_match(/class="x"/, html)
    end

    it "returns nil for a blank icon_path" do
      assert_nil game_icon_tag(nil)
      assert_nil game_icon_tag("")
    end

    it "returns nil (no raise) when the asset is not bundled" do
      assert_nil game_icon_tag("skill/china/does_not_exist.png")
    end
  end
end
