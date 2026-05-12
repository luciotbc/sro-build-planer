class SkillGroup < ApplicationRecord
  belongs_to :mastery
  belongs_to :skill_series, optional: true
  has_many :skills, dependent: :destroy
  has_many :skill_group_requirements, dependent: :destroy
  has_many :character_skills, dependent: :destroy

  validates :external_group_code, presence: true, uniqueness: true
end
