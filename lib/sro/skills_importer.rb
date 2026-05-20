require "csv"

module Sro
  class SkillsImporter
    # Configuration for field comparison per model
    COMPARISON_FIELDS = {
      Race: [:name],
      Mastery: %i[name mastery_type race_id],
      SkillGroup: [:mastery_id],
      Skill: %i[
        external_id
        external_skill_code
        mastery_level_req
        skill_level
        sp_cost
      ]
    }.freeze

    attr_reader :csv_path, :stats, :conflicts

    def initialize(csv_path = nil)
      @csv_path = csv_path || default_csv_path
      @stats = initialize_stats
      @conflicts = []
      @race_map = {} # Map race names to IDs
      @skill_group_cache = {} # Cache for skill group lookups
    end

    def import!
      log_header "🚀 Starting SRO Skills Import"
      log_info "CSV: #{@csv_path}"

      start_time = Time.current

      begin
        # Load and validate CSV
        load_csv

        # Phase 2: Foundation tables
        import_races
        import_masteries

        # Phase 3: Skill hierarchy
        import_skill_groups
        import_skills

        # Phase 5: Validation
        validate_data

        elapsed = (Time.current - start_time).round(2)
        report(elapsed)

        true
      rescue StandardError => e
        log_error "Import failed: #{e.message}"
        log_error e.backtrace.first(5).join("\n")
        false
      end
    end

    private

    # ───────────────────────────────────────────────────────────────────────────────
    # CSV Loading & Validation
    # ───────────────────────────────────────────────────────────────────────────────

    def load_csv
      log_section "Loading CSV"

      raise "CSV file not found: #{@csv_path}" unless File.exist?(@csv_path)

      @csv_data = CSV.read(@csv_path, headers: true, encoding: "utf-8")
      log_info "✓ Loaded #{@csv_data.count} rows"

      validate_csv_headers
    end

    def validate_csv_headers
      required_headers = %w[
        Race
        Mastery_ID
        Mastery_Name
        Mastery_Type
        Skill_ID
        Skill_Code
        Group_Code
        Skill_Level
        Weapon_Req1_Code
        Weapon_Req2_Code
        Name_KOR
        Name_EN
        Tooltip_KOR
        Tooltip_EN
        Study_KOR
        Study_EN
        Eff1_Type_Raw
        Eff1_Value
        Eff1_Element
        Eff1_Param_Min
        Eff1_Param_Max
      ]

      missing = required_headers - @csv_data.headers
      if missing.any?
        raise "Missing required CSV headers: #{missing.join(", ")}"
      end

      log_info "✓ CSV headers valid"
    end

    def default_csv_path
      Rails.root.join("doc", "import", "SRO_Skills_Complete.csv").to_s
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Phase 2: Foundation Tables
    # ───────────────────────────────────────────────────────────────────────────────

    def import_races
      log_section "Importing Races"

      races = { "Chinese" => 1, "European" => 2 }

      races.each do |race_name, external_id|
        record = Race.find_by(external_id: external_id)

        if record
          if compare_record(record, { name: race_name }, Race)
            @stats[:races][:skipped] += 1
            log_debug "  ⊘ Race external_id=#{external_id} already exists (matches)"
          else
            log_conflict "Race", external_id, record, { name: race_name }
            @stats[:races][:conflicts] += 1
          end
        else
          Race.create!(external_id: external_id, name: race_name)
          @stats[:races][:created] += 1
          @race_map[race_name] = external_id
          log_debug "  ✓ Created Race: #{race_name} (external_id=#{external_id})"
        end
      end

      log_info "Races: created=#{@stats[:races][:created]}, skipped=#{@stats[:races][:skipped]}, conflicts=#{
                 @stats[:races][:conflicts]
               }"
    end

    def import_masteries
      log_section "Importing Masteries"

      unique_masteries = extract_unique_masteries

      unique_masteries.each do |mastery_id, mastery_info|
        record = Mastery.find_by(external_id: mastery_id)

        if record
          comparison_data = {
            name: mastery_info[:name],
            mastery_type: mastery_info[:type],
            race_id: mastery_info[:race_id]
          }
          if compare_record(record, comparison_data, Mastery)
            @stats[:masteries][:skipped] += 1
            log_debug "  ⊘ Mastery external_id=#{mastery_id} already exists (matches)"
          else
            log_conflict "Mastery", mastery_id, record, comparison_data
            @stats[:masteries][:conflicts] += 1
          end
        else
          Mastery.create!(
            external_id: mastery_id,
            name: mastery_info[:name],
            mastery_type: mastery_info[:type],
            race_id: mastery_info[:race_id]
          )
          @stats[:masteries][:created] += 1
          log_debug "  ✓ Created Mastery: #{mastery_info[:name]} (external_id=#{mastery_id})"
        end
      end

      log_info "Masteries: created=#{@stats[:masteries][:created]}, skipped=#{
                 @stats[:masteries][:skipped]
               }, conflicts=#{@stats[:masteries][:conflicts]}"
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Phase 3: Skill Hierarchy
    # ───────────────────────────────────────────────────────────────────────────────

    def import_skill_groups
      log_section "Importing SkillGroups"

      unique_groups = extract_unique_skill_groups

      unique_groups.each do |group_code, group_info|
        record = SkillGroup.find_by(external_group_code: group_code)

        if record
          if record.mastery_id != group_info[:mastery_id]
            log_conflict "SkillGroup",
                         group_code,
                         record,
                         { mastery_id: group_info[:mastery_id] }
            @stats[:skill_groups][:conflicts] += 1
            next
          end
          @skill_group_cache[group_code] = record
        else
          record =
            SkillGroup.create!(
              description: group_info[:description],
              external_group_code: group_code,
              icon_path: group_info[:icon_path],
              mastery_id: group_info[:mastery_id],
              name: group_info[:name],
              tooltip: group_info[:tooltip]
            )
          @stats[:skill_groups][:created] += 1
          @skill_group_cache[group_code] = record
          log_debug "  ✓ Created SkillGroup: #{group_code} (mastery_id=#{group_info[:mastery_id]})"
        end
      end

      log_info "SkillGroups: created=#{@stats[:skill_groups][:created]}, updated=#{
                 @stats[:skill_groups][:updated]
               }, skipped=#{@stats[:skill_groups][:skipped]}, conflicts=#{@stats[:skill_groups][:conflicts]}"
    end

    def import_skills
      log_section "Importing Skills"

      @csv_data.each_with_index do |row, idx|
        skill_id = safe_int(row["Skill_ID"])
        skill_code = safe_string(row["Skill_Code"])
        group_code = safe_string(row["Group_Code"])

        record =
          Skill.find_by(external_id: skill_id, external_skill_code: skill_code)

        # Build comparison data from row
        comparison_data = build_skill_comparison_data(row)

        if record
          if compare_record(record, comparison_data, Skill)
            @stats[:skills][:skipped] += 1
            if idx < 3
              log_debug "  ⊘ Skill external_id=#{skill_id} already exists (matches)"
            end
          else
            log_conflict "Skill",
                         skill_id,
                         record,
                         comparison_data,
                         detail: true
            @stats[:skills][:conflicts] += 1
          end
        else
          skill_group = @skill_group_cache[group_code]
          unless skill_group
            log_error "  ✗ SkillGroup not found for group_code=#{group_code}, skipping skill"
            @stats[:skills][:errors] += 1
            next
          end

          skill_attrs = build_skill_attributes(row, skill_group)

          Skill.create!(skill_attrs)

          @stats[:skills][:created] += 1
          if idx < 3
            log_debug "  ✓ Created Skill: #{skill_code} (external_id=#{skill_id})"
          end
        end

        log_progress(idx, @csv_data.count, interval: 1000) if idx > 0
      end

      log_info "Skills: created=#{@stats[:skills][:created]}, skipped=#{
                 @stats[:skills][:skipped]
               }, conflicts=#{@stats[:skills][:conflicts]}, errors=#{
                 @stats[:skills][:errors]
               }"
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Phase 5: Validation & Reporting
    # ───────────────────────────────────────────────────────────────────────────────

    def validate_data
      log_section "Validating Data"

      # Count records
      log_info "Database state:"
      log_info "  Races: #{Race.count}"
      log_info "  Masteries: #{Mastery.count}"
      log_info "  SkillGroups: #{SkillGroup.count}"
      log_info "  Skills: #{Skill.count}"

      # Spot-check 5 random skills
      log_info "\nSpot-checking 5 random skills:"
      Skill
        .order("RANDOM()")
        .limit(5)
        .each do |skill|
          group = skill.skill_group&.external_group_code || "?"
          log_info "  #{skill.external_skill_code}: group=#{group}"
        end

      # Check FK referential integrity
      skills_without_group = Skill.where(skill_group_id: nil).count
      if skills_without_group > 0
        log_warn "⚠️  Found #{skills_without_group} skills without skill_group_id"
      end

      log_info "✓ Validation complete"
    end

    def report(elapsed_time = nil)
      log_section "Import Summary"

      total_created =
        @stats.values.sum { |table_stats| table_stats[:created] || 0 }
      total_updated =
        @stats.values.sum { |table_stats| table_stats[:updated] || 0 }
      total_skipped =
        @stats.values.sum { |table_stats| table_stats[:skipped] || 0 }
      total_conflicts =
        @stats.values.sum { |table_stats| table_stats[:conflicts] || 0 }
      total_errors =
        @stats.values.sum { |table_stats| table_stats[:errors] || 0 }

      log_info "┌────────────────────────────────────────┐"
      log_info "│ Per-Table Statistics                   │"
      log_info "├────────────────────────────────────────┤"

      @stats.each do |table, counters|
        created = counters[:created] || 0
        updated = counters[:updated] || 0
        skipped = counters[:skipped] || 0
        conflicts = counters[:conflicts] || 0
        errors = counters[:errors] || 0

        status = "✓" if conflicts.zero? && errors.zero?
        status ||= "⚠️" if conflicts > 0 || errors > 0

        log_info "│ #{status} #{table.to_s.ljust(20)} C:#{created.to_s.rjust(5)} U:#{updated.to_s.rjust(5)} S:#{
                   skipped.to_s.rjust(5)
                 } │"
      end

      log_info "├────────────────────────────────----────────┤"
      log_info "│ TOTALS                                     │"
      log_info "│  Created:  #{total_created.to_s.rjust(31)} │"
      log_info "│  Updated:  #{total_updated.to_s.rjust(31)} │"
      log_info "│  Skipped:  #{total_skipped.to_s.rjust(31)} │"
      log_info "│  Conflicts:#{total_conflicts.to_s.rjust(30)} │"
      log_info "│  Errors:    #{total_errors.to_s.rjust(31)} │"
      log_info "└─────────────----───────────────────────────┘"

      log_info "\n⏱️  Elapsed time: #{elapsed_time}s" if elapsed_time

      if @conflicts.any?
        log_section "Conflicts Summary"
        @conflicts.each { |conflict| log_info conflict }
      end

      log_info "\n✓ Import completed!"
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Helper Methods
    # ───────────────────────────────────────────────────────────────────────────────

    def initialize_stats
      {
        races: {
          created: 0,
          updated: 0,
          skipped: 0,
          conflicts: 0,
          errors: 0
        },
        masteries: {
          created: 0,
          updated: 0,
          skipped: 0,
          conflicts: 0,
          errors: 0
        },
        skill_groups: {
          created: 0,
          updated: 0,
          skipped: 0,
          conflicts: 0,
          errors: 0
        },
        skills: {
          created: 0,
          updated: 0,
          skipped: 0,
          conflicts: 0,
          errors: 0
        }
      }
    end

    def extract_unique_masteries
      masteries = {}
      @csv_data.each do |row|
        mastery_id = safe_int(row["Mastery_ID"])
        unless masteries[mastery_id]
          race_id = resolve_race_id(row["Race"])
          masteries[mastery_id] = {
            name: row["Mastery_Name"],
            type: row["Mastery_Type"],
            race_id: race_id
          }
        end
      end
      masteries
    end

    def extract_unique_skill_groups
      groups = {}
      @csv_data.each do |row|
        group_code = safe_string(row["Group_Code"]).strip
        unless groups[group_code]
          description = safe_string(row["Study_EN"])
          icon_path = safe_string(row["Icon_Path"])
          mastery_id = safe_int(row["Mastery_ID"])
          name = safe_string(row["Name_EN"])
          tooltip = safe_string(row["Tooltip_EN"])

          # Fix icon extension if needed
          icon_path = icon_path.sub(/\.ddj\z/, ".png") if icon_path.end_with?(
            ".ddj"
          )

          # Fix mastery_id is the external_id, we need to find the actual mastery record
          mastery = Mastery.find_by(external_id: mastery_id)

          groups[group_code] = {
            description: description,
            icon_path: icon_path,
            mastery_id: mastery&.id,
            name: name,
            tooltip: tooltip
          }
        end
      end
      groups
    end

    def build_skill_attributes(row, skill_group)
      {
        external_id: safe_int(row["Skill_ID"]),
        external_skill_code: safe_string(row["Skill_Code"]),
        mastery_level_req: safe_int(row["Mastery_Level_Req"]),
        skill_group_id: skill_group.id,
        skill_level: safe_int(row["Skill_Level"]),
        sp_cost: safe_int(row["SP_Cost"])
      }
    end

    def build_skill_comparison_data(row)
      {
        external_id: safe_int(row["Skill_ID"]),
        external_skill_code: safe_string(row["Skill_Code"]),
        mastery_level_req: safe_int(row["Mastery_Level_Req"]),
        skill_level: safe_int(row["Skill_Level"]),
        sp_cost: safe_int(row["SP_Cost"])
      }
    end

    def resolve_race_id(race_name)
      race_name = safe_string(race_name).strip
      race = Race.find_by(name: race_name)
      race&.id or raise "Race not found: #{race_name}"
    end

    def compare_record(record, csv_data, model_class)
      # Compare only specified fields
      fields_to_compare = COMPARISON_FIELDS[model_class.name.to_sym] || []

      fields_to_compare.all? do |field|
        record_value = record.send(field)
        csv_value = csv_data[field]

        # Handle type conversions
        record_value == csv_value || record_value.to_s == csv_value.to_s ||
          (record_value.nil? && csv_value.blank?)
      end
    end

    def resolve_skill_group_id(group_code)
      return nil if group_code.blank?

      skill_group =
        @skill_group_cache[group_code] ||
          SkillGroup.find_by(group_code: group_code)
      skill_group&.id
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Type Conversion Helpers
    # ───────────────────────────────────────────────────────────────────────────────

    def safe_string(value)
      value.to_s.strip
    rescue StandardError
      ""
    end

    def safe_int(value)
      Integer(value)
    rescue StandardError
      0
    end

    def safe_float(value)
      Float(value)
    rescue StandardError
      0.0
    end

    def safe_bool(value)
      case value.to_s.downcase.strip
      when "1", "true", "yes"
        true
      when "0", "false", "no", ""
        false
      else
        false
      end
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Logging Helpers
    # ───────────────────────────────────────────────────────────────────────────────

    def log_header(msg)
      puts "\n" + "═" * 80
      puts msg
      puts "═" * 80
    end

    def log_section(msg)
      puts "\n▸ #{msg}"
      puts "─" * 40
    end

    def log_info(msg)
      puts msg
    end

    def log_debug(msg)
      # Suppress in production, can add flag to enable
      # puts msg
    end

    def log_warn(msg)
      puts "⚠️  #{msg}"
    end

    def log_error(msg)
      puts "✗ #{msg}"
    end

    def log_conflict(model_name, id, db_record, csv_data, detail: false)
      conflict_msg =
        "⚠️  SKIP #{model_name}: external_id=#{id} (BD/CSV inconsistent)"
      conflict_msg += "\n   BD:  " + format_record_data(db_record)
      conflict_msg += "\n   CSV: " + format_csv_data(csv_data)
      log_warn conflict_msg
      @conflicts << conflict_msg
    end

    def format_record_data(record)
      # Format DB record for display
      key_fields =
        record.attributes.slice(*%w[id external_id name mastery_type]).compact
      key_fields.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
    end

    def format_csv_data(csv_data)
      # Format CSV data for display
      csv_data.map { |k, v| "#{k}=#{v.inspect}" }.join(", ")
    end

    def log_progress(current, total, interval: 1000)
      if (current % interval).zero?
        percent = ((current.to_f / total) * 100).round(1)
        puts "  ⟳ Progress: #{current}/#{total} (#{percent}%)"
      end
    end
  end
end
