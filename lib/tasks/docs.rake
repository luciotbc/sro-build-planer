namespace :docs do
  desc "Generate database ERD diagram at docs/diagrams/db-erd.svg"
  task erd: :environment do
    require "rails_erd/diagram/graphviz"

    Rails.application.eager_load!
    FileUtils.mkdir_p Rails.root.join("docs/diagrams")

    # Ref: https://voormedia.github.io/rails-erd/customise.html
    RailsERD::Diagram::Graphviz.create(
      filename: Rails.root.join("docs/diagrams/db-erd").to_s,
      filetype: "svg",
      title: "SRO Build Planer ERD",
      attributes: %i[foreign_keys content],
      indirect: false,
      inheritance: false,
      polymorphism: false,
      warn: false
    )

    puts "ERD saved to docs/diagrams/db-erd.svg"
  end
end
