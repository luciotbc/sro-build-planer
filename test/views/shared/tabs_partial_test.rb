require "test_helper"

class TabsPartialTest < ActionView::TestCase
  let(:tabs) do
    [
      { id: "weapon", label: "Weapon" },
      { id: "force", label: "Force" },
      { id: "recovery", label: "Recovery" }
    ]
  end

  describe "shared/tabs (pill variant)" do
    it "renders one button per tab wired to the tabs controller" do
      render partial: "shared/tabs", locals: { tabs: tabs }

      assert_select "[data-controller=tabs]" do
        assert_select "button[data-tabs-target=tab]", count: 3
        assert_select "button[data-tab-id=weapon]", text: "Weapon"
      end
    end

    it "marks the first tab active by default" do
      render partial: "shared/tabs", locals: { tabs: tabs }

      assert_select "button.on[data-tab-id=weapon]"
      assert_select "button.on", count: 1
    end

    it "marks the given tab active" do
      render partial: "shared/tabs", locals: { tabs: tabs, active: "force" }

      assert_select "button.on[data-tab-id=force]"
    end
  end

  describe "shared/tabs (underline variant)" do
    it "renders underline subtabs" do
      render partial: "shared/tabs",
             locals: {
               tabs: tabs,
               variant: :underline,
               name: "mastery"
             }

      assert_select "[data-controller=tabs][data-tabs-name-value=mastery]" do
        assert_select "button[data-tabs-target=tab]", count: 3
      end
    end
  end
end
