module Characters
  # Read-only presenter for the "current -> planned" totals shown on the home
  # summary card and the skill window footer.
  class PlanSummary
    def initialize(character)
      @character = character
    end

    def sp_current = sp_at(@character.current_level)
    def sp_planned = sp_at(@character.target_level)

    def mastery_current =
      mastery_levels.sum { |cm| cm.current_mastery_level.to_i }
    def mastery_planned =
      mastery_levels.sum { |cm| cm.target_mastery_level.to_i }

    def level_current = @character.current_level.to_i
    def level_planned = @character.target_level.to_i

    private

    def sp_at(level)
      return 0 if level.to_i.zero?

      LevelDatum.find_by(level: level)&.sp_cumulative.to_i
    end

    def mastery_levels
      @mastery_levels ||= @character.character_masteries.to_a
    end
  end
end
