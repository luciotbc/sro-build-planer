class SkillSeries < ApplicationRecord
  belongs_to :mastery
  has_many :skill_groups, dependent: :nullify
end
