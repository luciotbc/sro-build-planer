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

  # Crest icon asset filename for a race name (china.png / europe.png).
  def race_icon_file(race_name)
    race_name == "Chinese" ? "china.png" : "europe.png"
  end

  # Renders the race crest icon for a race name.
  def race_icon_tag(race_name, **options)
    image_tag(race_icon_file(race_name), alt: race_name, **options)
  end
end
