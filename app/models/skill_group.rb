class SkillGroup < ApplicationRecord
  belongs_to :mastery
  belongs_to :skill_series, optional: true
  has_many :skills, dependent: :destroy
  has_many :skill_group_requirements, dependent: :destroy
  has_many :character_skills, dependent: :destroy

  validates :external_group_code, presence: true, uniqueness: true

  def skill_at_level(level)
    if level < 0 || (max_skill_level && level > max_skill_level)
      raise ArgumentError,
            "level must be between 0 and #{max_skill_level || "∞"}, got #{level}"
    end

    skills.find_by(skill_level: level)
  end
end
