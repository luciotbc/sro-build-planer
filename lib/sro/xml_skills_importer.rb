require "nokogiri"

module Sro
  class XmlSkillsImporter
    RACES = {
      ch: {
        external_id: 1,
        name: "Chinese"
      },
      eu: {
        external_id: 2,
        name: "European"
      }
    }.freeze

    attr_reader :xml_path, :stats, :conflicts

    def initialize(xml_path = nil, race)
      @xml_path = xml_path || default_xml_path
      @stats = initialize_stats
      @conflicts = []
      @race = Race.find_by(external_id: RACES[race.to_sym][:external_id])
      @mastery_cache = {} # external_id => Mastery
      @series_cache = {} # [mastery_id, row] => SkillSeries
      @skill_group_cache = {} # external_id => SkillGroup
    end

    def import!
      log_header "Starting SRO XML Skills Import"
      log_info "XML: #{@xml_path}"

      start_time = Time.current

      begin
        load_xml
        import_masteries
        import_skill_series
        import_skill_groups
        import_skills
        import_skill_group_requirements
        import_level_data

        elapsed = (Time.current - start_time).round(2)
        report(elapsed)
        true
      rescue => e
        log_error "Import failed: #{e.message}"
        log_error e.backtrace.first(5).join("\n")
        false
      end
    end

    private

    # ───────────────────────────────────────────────────────────────────────────────
    # XML Loading
    # ───────────────────────────────────────────────────────────────────────────────

    def load_xml
      log_section "Loading XML"
      raise "XML file not found: #{@xml_path}" unless File.exist?(@xml_path)

      @doc = Nokogiri.XML(File.read(@xml_path))
      tab_count = @doc.xpath("//tab").count
      skill_count = @doc.xpath("//skillgroup/skill").count
      log_info "✓ Loaded #{tab_count} masteries, #{skill_count} skills"
    end

    def default_xml_path
      Rails.root.join("doc", "import", "skill_ch_small.xml").to_s
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Import Phases
    # ───────────────────────────────────────────────────────────────────────────────

    def import_masteries
      log_section "Importing Masteries"

      @doc
        .xpath("//tab")
        .each do |tab|
          external_id = tab["id"].to_i
          name = tab["name"]
          mastery_type = tab["stype"]

          record = Mastery.find_by(external_id: external_id)
          if record
            @mastery_cache[external_id] = record
            @stats[:masteries][:skipped] += 1
            log_debug "  ⊘ Mastery '#{name}' already exists"
          else
            record =
              Mastery.create!(
                external_id: external_id,
                name: name,
                mastery_type: mastery_type,
                race_id: @race.id
              )
            @mastery_cache[external_id] = record
            @stats[:masteries][:created] += 1
            log_debug "  ✓ Created Mastery: #{name} (external_id=#{external_id})"
          end
        end

      log_info "Masteries: created=#{@stats[:masteries][:created]}, skipped=#{@stats[:masteries][:skipped]}"
    end

    def import_skill_series
      log_section "Importing SkillSeries"

      @doc
        .xpath("//tab")
        .each do |tab|
          mastery_external_id = tab["id"].to_i
          mastery = @mastery_cache[mastery_external_id]
          next unless mastery

          tab
            .xpath("series")
            .each do |series|
              row_position = series["row"].to_i
              title = series["title"]
              icon_path = normalize_icon_path(series["pict"])

              record =
                SkillSeries.find_by(
                  mastery_id: mastery.id,
                  row_position: row_position
                )
              cache_key = [mastery.id, row_position]

              if record
                @series_cache[cache_key] = record
                @stats[:skill_series][:skipped] += 1
              else
                record =
                  SkillSeries.create!(
                    mastery_id: mastery.id,
                    row_position: row_position,
                    title: title,
                    icon_path: icon_path
                  )
                @series_cache[cache_key] = record
                @stats[:skill_series][:created] += 1
                log_debug "  ✓ Created SkillSeries: #{title}"
              end
            end
        end

      log_info "SkillSeries: created=#{@stats[:skill_series][:created]}, skipped=#{@stats[:skill_series][:skipped]}"
    end

    def import_skill_groups
      log_section "Importing SkillGroups"

      @doc
        .xpath("//tab")
        .each do |tab|
          mastery_external_id = tab["id"].to_i
          mastery = @mastery_cache[mastery_external_id]
          next unless mastery

          tab
            .xpath("series")
            .each do |series|
              row_position = series["row"].to_i
              skill_series = @series_cache[[mastery.id, row_position]]

              series
                .xpath("skillgroup")
                .each do |sg|
                  external_id = sg["id"].to_i
                  name = sg["name"]
                  description = sg["desc"]
                  icon_path = normalize_icon_path(sg["pict"])
                  col_position = sg["col"].to_i
                  max_level = sg.xpath("skill").count

                  record = SkillGroup.find_by(external_id: external_id)
                  if record
                    @skill_group_cache[external_id] = record
                    @stats[:skill_groups][:skipped] += 1
                  else
                    record =
                      SkillGroup.create!(
                        external_id: external_id,
                        external_group_code: external_id.to_s,
                        name: name,
                        description: description,
                        icon_path: icon_path,
                        col_position: col_position,
                        mastery_id: mastery.id,
                        skill_series_id: skill_series&.id,
                        max_level: max_level
                      )
                    @skill_group_cache[external_id] = record
                    @stats[:skill_groups][:created] += 1
                    log_debug "  ✓ Created SkillGroup: #{name} (external_id=#{external_id})"
                  end
                end
            end
        end

      log_info "SkillGroups: created=#{@stats[:skill_groups][:created]}, skipped=#{@stats[:skill_groups][:skipped]}"
    end

    def import_skills
      log_section "Importing Skills"

      @doc
        .xpath("//skillgroup/skill")
        .each do |skill_node|
          sg_external_id = skill_node.parent["id"].to_i
          skill_group = @skill_group_cache[sg_external_id]

          unless skill_group
            log_error "  ✗ SkillGroup external_id=#{sg_external_id} not found, skipping skill"
            @stats[:skills][:errors] += 1
            next
          end

          external_id = skill_node["id"].to_i
          stack = skill_node["stack"].to_i
          mastery_level_req = skill_node["lv"].to_i
          sp_cost = skill_node["sp"].to_i
          mp_cost = skill_node["mp"].to_i

          record = Skill.find_by(external_id: external_id)
          if record
            @stats[:skills][:skipped] += 1
          else
            Skill.create!(
              external_id: external_id,
              external_skill_code: "SK_#{external_id}",
              skill_group_id: skill_group.id,
              skill_level: stack,
              stack: stack,
              mastery_level_req: mastery_level_req,
              sp_cost: sp_cost,
              mp_cost: mp_cost
            )
            @stats[:skills][:created] += 1
            log_debug "  ✓ Created Skill: SK_#{external_id} (group=#{skill_group.name}, stack=#{stack})"
          end
        end

      s = @stats[:skills]
      log_info "Skills: created=#{s[:created]}, skipped=#{s[:skipped]}, errors=#{s[:errors]}"
    end

    def import_skill_group_requirements
      log_section "Importing SkillGroupRequirements"

      # Read requirements from the first skill in each skillgroup — requirements
      # are uniform across all skills within a group.
      @doc
        .xpath("//skillgroup")
        .each do |sg_node|
          sg_external_id = sg_node["id"].to_i
          skill_group = @skill_group_cache[sg_external_id]
          next unless skill_group

          first_skill = sg_node.xpath("skill").first
          next unless first_skill

          [1, 2, 3].each do |n|
            required_group_ext_id = first_skill["prv#{n}"].to_i
            required_level = first_skill["prvrq#{n}"].to_i
            next if required_group_ext_id.zero?

            required_group = @skill_group_cache[required_group_ext_id]
            unless required_group
              log_warn "Required SkillGroup external_id=#{required_group_ext_id} not found for '#{skill_group.name}'"
              @stats[:skill_group_requirements][:errors] += 1
              next
            end

            existing =
              SkillGroupRequirement.find_by(
                skill_group_id: skill_group.id,
                required_group_id: required_group.id
              )

            if existing
              @stats[:skill_group_requirements][:skipped] += 1
            else
              SkillGroupRequirement.create!(
                skill_group_id: skill_group.id,
                required_group_id: required_group.id,
                required_level: required_level
              )
              @stats[:skill_group_requirements][:created] += 1
              log_debug "  ✓ Requirement: #{skill_group.name} requires #{required_group.name} lv#{required_level}"
            end
          end
        end

      sgr = @stats[:skill_group_requirements]
      log_info "SkillGroupRequirements: created=#{sgr[:created]}, skipped=#{sgr[:skipped]}, errors=#{sgr[:errors]}"
    end

    def import_level_data
      log_section "Importing LevelData"

      sp_cumulative = 0

      @doc
        .xpath("//LevelData/data")
        .each do |data_node|
          level = data_node["lv"].to_i
          xp_required = data_node["xp"].to_i
          sp_gained = data_node["sp"].to_i
          sp_cumulative += sp_gained

          record = LevelDatum.find_by(level: level)
          if record
            @stats[:level_data][:skipped] += 1
          else
            LevelDatum.create!(
              level: level,
              xp_required: xp_required,
              sp_gained: sp_gained,
              sp_cumulative: sp_cumulative
            )
            @stats[:level_data][:created] += 1
          end
        end

      log_info "LevelData: created=#{@stats[:level_data][:created]}, skipped=#{@stats[:level_data][:skipped]}"
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Helpers
    # ───────────────────────────────────────────────────────────────────────────────

    def normalize_icon_path(path)
      return nil if path.nil?

      path.sub(/\.ddj\z/, ".png")
    end

    def initialize_stats
      tables = %i[
        races
        masteries
        skill_series
        skill_groups
        skills
        skill_group_requirements
        level_data
      ]
      tables.each_with_object({}) do |key, h|
        h[key] = { created: 0, skipped: 0, errors: 0 }
      end
    end

    def report(elapsed_time = nil)
      log_section "Import Summary"

      total_created = @stats.values.sum { |s| s[:created] }
      total_skipped = @stats.values.sum { |s| s[:skipped] }
      total_errors = @stats.values.sum { |s| s[:errors] }

      log_info "┌────────────────────────────────────────────┐"
      log_info "│ Per-Table Statistics                       │"
      log_info "├────────────────────────────────────────────┤"

      @stats.each do |table, counters|
        status = counters[:errors].zero? ? "✓" : "⚠️"
        c = counters[:created].to_s.rjust(4)
        s = counters[:skipped].to_s.rjust(4)
        log_info "│ #{status} #{table.to_s.ljust(28)} C:#{c} S:#{s} │"
      end

      log_info "├────────────────────────────────────────────┤"
      log_info "│ TOTALS                                     │"
      log_info "│  Created: #{total_created.to_s.rjust(33)} │"
      log_info "│  Skipped: #{total_skipped.to_s.rjust(33)} │"
      log_info "│  Errors:  #{total_errors.to_s.rjust(33)} │"
      log_info "└────────────────────────────────────────────┘"

      log_info "\n⏱️  Elapsed: #{elapsed_time}s" if elapsed_time
      log_info "\n✓ Import completed!"
    end

    # ───────────────────────────────────────────────────────────────────────────────
    # Logging
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

    def log_info(msg) = puts(msg)

    def log_debug(_msg)
      # uncomment to enable verbose output:
      # puts _msg
    end

    def log_warn(msg) = puts("⚠️  #{msg}")

    def log_error(msg) = puts("✗ #{msg}")
  end
end
