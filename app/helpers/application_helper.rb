module ApplicationHelper
  # Renders an <img> for a stored game icon_path (relative to
  # app/assets/images, e.g. "skill/china/foo.png"). Returns nil when the path
  # is blank or the asset is not bundled, so callers can fall back to an empty
  # frame instead of raising Propshaft::MissingAssetError.
  def game_icon_tag(icon_path, **options)
    return if icon_path.blank?
    return unless Rails.application.assets.load_path.find(icon_path)

    image_tag(icon_path, **options)
  end

  # Renders the race crest icon (china.png / europe.png) for a race name.
  def race_icon_tag(race_name, **options)
    icon = race_name == "Chinese" ? "china.png" : "europe.png"
    image_tag(icon, alt: race_name, **options)
  end
end
