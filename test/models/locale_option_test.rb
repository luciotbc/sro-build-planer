require "test_helper"

class LocaleOptionTest < ActiveSupport::TestCase
  it "is in parity with the available locales" do
    assert_equal I18n.available_locales.map(&:to_s).sort,
                 LocaleOption.all.map(&:code).sort
  end

  it "orders entries by locale code" do
    codes = LocaleOption.all.map(&:code)
    assert_equal codes.sort, codes
  end

  it "exposes a flag and native name per option" do
    pt = LocaleOption.all.find { |o| o.code == "pt-BR" }
    assert_equal "🇧🇷", pt.flag
    assert_equal "Português (BR)", pt.native_name
  end

  it "looks up a flag by code" do
    assert_equal "🇧🇷", LocaleOption.flag("pt-BR")
    assert_equal "🇧🇷", LocaleOption.flag(:"pt-BR")
  end
end
