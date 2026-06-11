require "test_helper"

class ButtonPartialTest < ActionView::TestCase
  describe "shared/button" do
    it "renders a primary button by default" do
      render partial: "shared/button", locals: { label: "Edit Planned" }

      assert_select "button.btn-primary[type=button]", text: "Edit Planned"
    end

    it "renders a ghost variant" do
      render partial: "shared/button",
             locals: {
               label: "Cancel",
               variant: :ghost
             }

      assert_select "button.btn-ghost", text: "Cancel"
    end

    it "renders an anchor when href is given" do
      render partial: "shared/button",
             locals: {
               label: "Open",
               href: "/somewhere"
             }

      assert_select "a.btn-primary[href=?]", "/somewhere", text: "Open"
    end

    it "renders full width when block is true" do
      render partial: "shared/button", locals: { label: "Save", block: true }

      assert_select "button.w-full"
    end

    it "merges extra html attributes" do
      render partial: "shared/button",
             locals: {
               label: "Go",
               html: {
                 "data-test": "x"
               }
             }

      assert_select "button[data-test=x]"
    end
  end
end
