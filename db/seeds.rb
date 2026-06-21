# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require "erb"

fixture_path = Rails.root.join("test/fixtures")

races =
  YAML
    .safe_load(
      ERB.new(File.read(fixture_path.join("races.yml")).to_s).result,
      aliases: true
    )
    .transform_values do |attrs|
      Race.find_or_create_by!(
        external_id: attrs["external_id"],
        name: attrs["name"]
      )
    end

masteries =
  YAML.safe_load(
    ERB.new(File.read(fixture_path.join("masteries.yml")).to_s).result,
    aliases: true
  )

masteries.each do |_fixture_name, attrs|
  Mastery
    .find_or_initialize_by(external_id: attrs["external_id"])
    .tap do |mastery|
      mastery.name = attrs["name"]
      mastery.mastery_type = attrs["mastery_type"]
      mastery.race = races.fetch(attrs["race"])
      mastery.save!
    end
end

# Default user
User.find_or_create_by!(email_address: "user@mail.com") do |user|
  user.password = "Password1!"
  user.password_confirmation = "Password1!"
  user.email_confirmed_at = Time.current
  user.email_opt_in = true
end
