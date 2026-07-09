require "test_helper"

class FooterTest < ActionDispatch::IntegrationTest
  test "the footer renders on public pages with the author link and locale links" do
    get root_url

    assert_response :success
    assert_select "footer.site-footer" do
      assert_select "a.site-footer-link[href=?]", "https://lucio.app/"
      assert_select ".site-footer-locale", minimum: 1
      assert_select "a.site-footer-navlink[href=?]",
                    privacy_path,
                    text: "Privacy Policy"
      assert_select "a.site-footer-navlink[href=?]",
                    terms_path,
                    text: "Terms of Service"
    end
  end

  test "the footer marks the active locale and offers the others as switch buttons" do
    get root_url, headers: { "Accept-Language" => "pt-BR" }

    assert_response :success
    # Active locale is a non-interactive marker; the rest are switch buttons.
    assert_select ".site-footer-locale.is-active", text: "Português (BR)"
    assert_select "form.site-footer-locale-item",
                  count: LocaleOption.all.size - 1
  end

  test "the footer renders on authenticated pages too" do
    sign_in_as create(:user, :confirmed)

    get settings_url

    assert_response :success
    assert_select "footer.site-footer"
  end
end
