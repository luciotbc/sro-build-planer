namespace :import do
  desc "Import SRO Skills from CSV"
  task :skills, [ :csv_path ] => :environment do |t, args|
    require_relative "../../lib/sro/skills_importer"

    csv_path = args.csv_path || Rails.root.join("doc", "import", "SRO_Skills_Complete.csv").to_s

    importer = SRO::SkillsImporter.new(csv_path)
    success = importer.import!

    exit(1) unless success
  end
end
