require "test_helper"

# Verifies that the living /docs/design_system page includes all composite
# components added in tasks 010–016 (spec 017 AC1).
#
# The route is development-only, so we draw it temporarily with `with_routing`
# and bypass the env guard by stubbing ensure_development on the controller.
class DesignSystemParityTest < ActionDispatch::IntegrationTest
  def render_ds(&block)
    DocsController.skip_before_action :ensure_development
    with_routing do |set|
      set.draw { get "docs/design_system" => "docs#design_system" }
      get "/docs/design_system"
      block.call
    end
  ensure
    DocsController.prepend_before_action :ensure_development
  end

  test "design system renders toast section" do
    render_ds { assert_select "#toast" }
  end

  test "design system renders empty state section" do
    render_ds { assert_select "#empty_state" }
  end

  test "design system renders stats summary section" do
    render_ds { assert_select "#stats_summary" }
  end

  test "design system renders mastery header section" do
    render_ds { assert_select "#mastery_header" }
  end

  test "design system renders editor skill row section" do
    render_ds { assert_select "#editor_skill_row" }
  end

  test "design system renders chars drawer section" do
    render_ds { assert_select "#chars_drawer" }
  end

  test "toast section contains the toast partial markup" do
    render_ds { assert_select "[data-controller~='toast']" }
  end

  test "empty state section shows a title and description" do
    render_ds { assert_select ".flex.flex-col", text: /character/i }
  end

  test "stats summary section shows Skill points label" do
    render_ds { assert_select "*", text: /Skill points/ }
  end
end
