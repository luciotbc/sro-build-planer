require "csv"
require "zip"

module Users
  # Builds the "Export my data" archive: user.csv (personal data, never ids)
  # plus one build CSV per character, zipped as srolabs_<UTC timestamp>.zip
  # (spec 09 R8). Pure data in / data out — mailing is the job's concern.
  class ExportDataService
    USER_COLUMNS = %w[
      email_address
      email_confirmed_at
      email_opt_in
      created_at
    ].freeze

    CHARACTER_COLUMNS = %w[
      mastery_name
      mastery_current_level
      mastery_future_level
      skill_group_name
      current_skill_level
      future_skill_level
    ].freeze

    RACE_PREFIXES = { "chinese" => "ch", "european" => "eu" }.freeze

    def self.call(user:) = new(user).call

    def initialize(user)
      @user = user
    end

    def call
      filename = Time.now.utc.strftime("srolabs_%Y%m%d%H%M%S.zip")
      ServiceResult.ok(data: { filename: filename, content: zip_content })
    end

    private

    def zip_content
      Zip::OutputStream
        .write_buffer do |zip|
          csv_files.each do |name, csv|
            zip.put_next_entry(name)
            zip.write(csv)
          end
        end
        .string
    end

    def csv_files
      files = { "user.csv" => user_csv }
      @user
        .characters
        .includes(
          character_masteries: :mastery,
          character_skills: {
            skill_group: :mastery
          }
        )
        .each do |character|
          files[unique_name(files, character)] = character_csv(character)
        end
      files
    end

    def user_csv
      CSV.generate do |csv|
        csv << USER_COLUMNS
        csv << USER_COLUMNS.map { |column| @user.public_send(column) }
      end
    end

    def character_csv(character)
      mastery_levels = character.character_masteries.index_by(&:mastery_id)

      CSV.generate do |csv|
        csv << CHARACTER_COLUMNS
        character.character_skills.each do |character_skill|
          mastery = character_skill.skill_group.mastery
          levels = mastery_levels[mastery.id]
          csv << [
            mastery.name,
            levels&.current_mastery_level,
            levels&.target_mastery_level,
            character_skill.skill_group.name,
            character_skill.current_skill_level,
            character_skill.target_skill_level
          ]
        end
      end
    end

    # ch_BuckTBC_120.csv — race prefix, filesystem-safe name, current level;
    # duplicate names get _2, _3… suffixes.
    def unique_name(files, character)
      prefix = RACE_PREFIXES.fetch(character.race.name.downcase, "xx")
      safe_name = character.name.gsub(/[^0-9A-Za-z_-]/, "_")
      base = "#{prefix}_#{safe_name}_#{character.current_level || 1}"

      name = "#{base}.csv"
      counter = 1
      name = "#{base}_#{counter += 1}.csv" while files.key?(name)
      name
    end
  end
end
