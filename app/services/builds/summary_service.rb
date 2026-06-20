module Builds
  class SummaryService
    def self.call(character) = new(character).call

    def initialize(character)
      @character = character
      @warnings = []
    end

    def call
      masteries = @character.character_masteries.to_a
      skills = @character.character_skills.to_a

      level_data = load_level_data(masteries)
      skill_costs = load_skill_costs(skills)

      mastery_sp = compute_mastery_sp(masteries, level_data)
      skill_sp = compute_skill_sp(skills, skill_costs)

      sp = {
        current: mastery_sp[:current] + skill_sp[:current],
        planned: mastery_sp[:planned] + skill_sp[:planned]
      }
      sp[:delta] = sp[:planned] - sp[:current]

      mastery_total = {
        current: masteries.sum { |m| m.current_mastery_level.to_i },
        planned: masteries.sum { |m| m.target_mastery_level.to_i }
      }
      mastery_total[:delta] = mastery_total[:planned] - mastery_total[:current]

      required_level = {
        current: @character.current_level.to_i,
        planned: @character.target_level.to_i
      }
      required_level[:delta] = required_level[:planned] -
        required_level[:current]

      ServiceResult.ok(
        data: {
          skill_points: sp,
          mastery_total: mastery_total,
          required_level: required_level
        },
        warnings: @warnings
      )
    end

    private

    # Load sp_cumulative by level into a hash — ONE query, no N+1.
    # Per spec 02 R1a: summed per-mastery-row in Ruby, never via IN (which deduplicates).
    def load_level_data(masteries)
      levels =
        masteries
          .flat_map do |cm|
            [cm.current_mastery_level.to_i, cm.target_mastery_level.to_i]
          end
          .uniq
          .reject(&:zero?)
      return {} if levels.empty?

      LevelDatum.where(level: levels).index_by(&:level)
    end

    def load_skill_costs(skills)
      group_ids = skills.map(&:skill_group_id).uniq
      return {} if group_ids.empty?

      Skill.where(skill_group_id: group_ids).group_by(&:skill_group_id)
    end

    def compute_mastery_sp(masteries, level_data)
      current = 0
      planned = 0
      masteries.each do |cm|
        current += sp_cumulative_for(cm.current_mastery_level, level_data)
        planned += sp_cumulative_for(cm.target_mastery_level, level_data)
      end
      { current:, planned: }
    end

    def sp_cumulative_for(level, level_data)
      return 0 if level.nil? || level.zero?

      datum = level_data[level.to_i]
      if datum.nil?
        @warnings << I18n.t("warnings.level_datum_missing", level:)
        return 0
      end
      datum.sp_cumulative.to_i
    end

    def compute_skill_sp(skills, skill_costs)
      current = 0
      planned = 0
      skills.each do |cs|
        group_skills = skill_costs[cs.skill_group_id] || []
        current += cumulative_sp(group_skills, cs.current_skill_level.to_i)
        planned += cumulative_sp(group_skills, cs.target_skill_level.to_i)
      end
      { current:, planned: }
    end

    def cumulative_sp(group_skills, level)
      return 0 if level.zero?

      group_skills
        .select { |s| s.skill_level.to_i.between?(1, level) }
        .sum { |s| s.sp_cost.to_i }
    end
  end
end
