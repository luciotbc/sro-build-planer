module SkillPlansHelper
  # Level being edited for the active kind (current vs planned).
  def plan_level(character_skill)
    return 0 unless character_skill

    if kind == :current
      character_skill.current_skill_level.to_i
    else
      character_skill.target_skill_level.to_i
    end
  end

  def plan_mastery_level(window)
    if kind == :current
      window.mastery_level_current
    else
      window.mastery_level_planned
    end
  end
end
