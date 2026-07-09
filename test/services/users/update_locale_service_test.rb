require "test_helper"

class Users::UpdateLocaleServiceTest < ActiveSupport::TestCase
  it "persists a supported locale" do
    user = create(:user)

    result = Users::UpdateLocaleService.call(user: user, locale: "pt-BR")

    assert result.success?
    assert_equal "pt-BR", user.reload.locale
  end

  it "accepts a symbol locale" do
    user = create(:user)

    result = Users::UpdateLocaleService.call(user: user, locale: :ko)

    assert result.success?
    assert_equal "ko", user.reload.locale
  end

  it "fails on an unsupported locale and leaves the selection unchanged" do
    user = create(:user, locale: "es")

    result = Users::UpdateLocaleService.call(user: user, locale: "xx")

    assert_not result.success?
    assert result.errors.any?
    assert_equal "es", user.reload.locale
  end

  it "validates a guest's locale without persisting anything" do
    result = Users::UpdateLocaleService.call(user: nil, locale: "pt-BR")

    assert result.success?
    assert_equal "pt-BR", result.data
  end

  it "fails on an unsupported locale for a guest" do
    result = Users::UpdateLocaleService.call(user: nil, locale: "xx")

    assert_not result.success?
    assert result.errors.any?
  end
end
