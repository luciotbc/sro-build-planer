# Picks the request locale from the browser's Accept-Language header
# (per docs/specs/08-i18n-conventions.md R12): exact tag match first
# (pt-BR → pt-BR), then language-only match (pt → pt-BR, en-US → en,
# zh-Hans → zh-CN), else I18n.default_locale.
module LocaleDetection
  extend ActiveSupport::Concern

  included { around_action :switch_locale }

  private

  def switch_locale(&action)
    I18n.with_locale(browser_locale, &action)
  end

  def browser_locale
    requested_language_tags
      .filter_map { |tag| supported_locale_for(tag) }
      .first || I18n.default_locale
  end

  # Accept-Language tags ordered by q-value, e.g.
  # "en;q=0.5,tr;q=0.9" → ["tr", "en"].
  def requested_language_tags
    request.headers["Accept-Language"]
      .to_s
      .split(",")
      .filter_map do |entry|
        tag, q = entry.split(";q=")
        [tag.strip, q.to_f.nonzero? || 1.0] unless tag.blank?
      end
      .sort_by { |_tag, q| -q }
      .map(&:first)
  end

  def supported_locale_for(tag)
    exact_match(tag) || language_match(tag)
  end

  def exact_match(tag)
    I18n.available_locales.find { |locale| locale.to_s.casecmp?(tag) }
  end

  def language_match(tag)
    language = tag.split("-").first
    I18n.available_locales.find do |locale|
      locale.to_s.split("-").first.casecmp?(language)
    end
  end
end
