module Characters
  # Read-only presenter for the skills window (home card and editor): resolves
  # the active mastery type tab, the active mastery, its series/groups and the
  # character's levels per skill group.
  class SkillWindow
    TYPE_ORDER = Mastery::MASTERY_TYPES

    attr_reader :character

    def initialize(character, group: nil, mastery_id: nil)
      @character = character
      @group_param = group
      @mastery_id_param = mastery_id
    end

    def mastery_types
      @mastery_types ||=
        race_masteries
          .distinct
          .pluck(:mastery_type)
          .sort_by { |t| TYPE_ORDER.index(t) || TYPE_ORDER.size }
    end

    def active_type
      @active_type ||=
        if mastery_types.include?(@group_param)
          @group_param
        else
          mastery&.mastery_type || mastery_types.first
        end
    end

    def masteries
      @masteries ||=
        race_masteries.where(mastery_type: active_type).order(:external_id)
    end

    def mastery
      return @mastery if defined?(@mastery)

      @mastery =
        (race_masteries.find_by(id: @mastery_id_param) if @mastery_id_param)
      @mastery ||=
        race_masteries
          .where(mastery_type: @group_param.presence || mastery_types.first)
          .order(:external_id)
          .first
    end

    def series
      @series ||=
        mastery
          .skill_series
          .order(:row_position)
          .includes(skill_groups: [])
          .map { |s| [s, s.skill_groups.sort_by { |g| g.col_position.to_i }] }
    end

    def character_mastery
      @character_mastery ||=
        character.character_masteries.find_by(mastery: mastery)
    end

    def mastery_level_current = character_mastery&.current_mastery_level.to_i
    def mastery_level_planned = character_mastery&.target_mastery_level.to_i
    def mastery_level_cap = character.target_level.to_i

    # { skill_group_id => CharacterSkill }
    def character_skills
      @character_skills ||=
        character
          .character_skills
          .where(
            skill_group_id: series.flat_map { |_, groups| groups }.map(&:id)
          )
          .index_by(&:skill_group_id)
    end

    def summary
      @summary ||= PlanSummary.new(character)
    end

    private

    def race_masteries
      Mastery.where(race_id: character.race_id)
    end
  end
end
