# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require "erb"

fixture_path = Rails.root.join("test/fixtures")

YAML.safe_load(ERB.new(File.read(fixture_path.join("races.yml")).to_s).result, aliases: true)
          .transform_values do |attrs|
  Race.find_or_create_by!(external_id: attrs["external_id"], name: attrs["name"])
end
