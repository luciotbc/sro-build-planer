namespace :import do
  desc "Import SRO Skills from CSV"
  task :skills, [:csv_path] => :environment do |t, args|
    require_relative "../../lib/sro/skills_importer"

    csv_path =
      args.csv_path ||
        Rails.root.join("doc", "import", "SRO_Skills_Complete.csv").to_s

    importer = Sro::SkillsImporter.new(csv_path)
    success = importer.import!

    exit(1) unless success
  end

  desc "Import SRO Skills from XML (e.g. skill_ch_small.xml)"
  task skills_xml: :environment do |t, args|
    require_relative "../../lib/sro/xml_skills_importer"
    ch_xml_path =
      args.xml_path || Rails.root.join("doc", "import", "skill_ch.xml").to_s

    importer = Sro::XmlSkillsImporter.new(ch_xml_path, :ch)
    ch_success = importer.import!

    eu_xml_path =
      args.xml_path || Rails.root.join("doc", "import", "skill_eu.xml").to_s

    importer = Sro::XmlSkillsImporter.new(eu_xml_path, :eu)
    eu_success = importer.import!

    success = ch_success && eu_success

    exit(1) unless success
  end
end
