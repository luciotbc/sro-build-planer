class CharacterSkill < ApplicationRecord
  belongs_to :character, inverse_of: :character_skills
  belongs_to :skill_group

  validates :skill_group_id, uniqueness: { scope: :character_id }

  def current_skill
    return nil if current_skill_level.nil? || current_skill_level == 0

    skill_group.skill_at_level(current_skill_level)
  end

  def target_skill
    return nil if target_skill_level.nil? || target_skill_level == 0

    skill_group.skill_at_level(target_skill_level)
  end
end
