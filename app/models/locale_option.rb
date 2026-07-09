# Display metadata (flag + native name) for each supported UI locale, used by
# the language submenu (docs/todo/033). Native names are shown in their own
# language and are DISPLAY DATA — never translated strings, so they live here
# and not in config/locales (spec 08). Ordered by locale code to match the
# submenu in the character_show.html mockup.
module LocaleOption
  Option = Data.define(:code, :flag, :native_name)

  ENTRIES = {
    "en" => {
      flag: "🇺🇸",
      native_name: "English"
    },
    "es" => {
      flag: "🇪🇸",
      native_name: "Español"
    },
    "ko" => {
      flag: "🇰🇷",
      native_name: "한국어"
    },
    "pt-BR" => {
      flag: "🇧🇷",
      native_name: "Português (BR)"
    },
    "tr" => {
      flag: "🇹🇷",
      native_name: "Türkçe"
    },
    "zh-CN" => {
      flag: "🇨🇳",
      native_name: "中文 (简体)"
    }
  }.freeze

  def self.all
    ENTRIES.map { |code, meta| Option.new(code: code, **meta) }
  end

  def self.flag(code) = ENTRIES.dig(code.to_s, :flag)
end
