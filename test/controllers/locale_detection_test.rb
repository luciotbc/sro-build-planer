require "test_helper"

class LocaleDetectionTest < ActionDispatch::IntegrationTest
  def cta_in(locale)
    I18n.t("home.cta_band.cta", locale:)
  end

  def get_root(accept_language)
    get root_path, headers: { "Accept-Language" => accept_language }
    assert_response :success
  end

  it "defaults to :en without an Accept-Language header" do
    get root_path
    assert_response :success
    assert_includes response.body, cta_in(:en)
  end

  it "uses an exact supported locale" do
    get_root "pt-BR,pt;q=0.9,en;q=0.8"
    assert_includes response.body, cta_in(:"pt-BR")
  end

  it "matches exact tags case-insensitively" do
    get_root "PT-br"
    assert_includes response.body, cta_in(:"pt-BR")
  end

  it "maps a bare language to its regional locale (pt → pt-BR)" do
    get_root "pt"
    assert_includes response.body, cta_in(:"pt-BR")
  end

  it "maps a regional tag to its bare locale (en-US → en)" do
    get_root "en-US,en;q=0.9"
    assert_includes response.body, cta_in(:en)
  end

  it "maps unsupported regions to the language locale (es-MX → es)" do
    get_root "es-MX"
    assert_includes response.body, cta_in(:es)
  end

  it "respects q priorities over header order" do
    get_root "en;q=0.5,tr;q=0.9"
    assert_includes response.body, cta_in(:tr)
  end

  it "picks the first supported language in priority order" do
    get_root "fr-FR,fr;q=0.9,ko;q=0.8,en;q=0.5"
    assert_includes response.body, cta_in(:ko)
  end

  it "maps zh variants to zh-CN" do
    get_root "zh-Hans"
    assert_includes response.body, cta_in(:"zh-CN")

    get_root "zh"
    assert_includes response.body, cta_in(:"zh-CN")
  end

  it "falls back to :en when nothing is supported" do
    get_root "fr-FR,de;q=0.8,*;q=0.1"
    assert_includes response.body, cta_in(:en)
  end

  it "falls back to :en on a malformed header" do
    get_root ";;;,,q=;zzzz"
    assert_includes response.body, cta_in(:en)
  end

  it "resets the locale after the request" do
    get_root "pt-BR"
    assert_equal :en, I18n.locale
  end

  # Signed-in users see the app home (not the landing CTA band), so assert on
  # a string the authenticated layout always renders: the user-menu label.
  def menu_label_in(locale)
    I18n.t("shared.user_menu.label", locale:)
  end

  it "prefers a signed-in user's saved locale over Accept-Language" do
    sign_in_as create(:user, locale: "ko")
    get_root "pt-BR,en;q=0.9"
    assert_includes response.body, menu_label_in(:ko)
  end

  it "falls back to Accept-Language when the user has no saved locale" do
    sign_in_as create(:user, locale: nil)
    get_root "tr,en;q=0.9"
    assert_includes response.body, menu_label_in(:tr)
  end

  # A guest's chosen locale is kept in the session and beats Accept-Language.
  it "prefers a guest's session locale over Accept-Language" do
    patch settings_locale_url, params: { locale: "es" }
    get_root "tr,en;q=0.9"
    assert_includes response.body, cta_in(:es)
  end

  it "prefers a signed-in user's saved locale over the session locale" do
    patch settings_locale_url, params: { locale: "es" }
    sign_in_as create(:user, locale: "ko")
    get_root "tr,en;q=0.9"
    assert_includes response.body, menu_label_in(:ko)
  end
end
