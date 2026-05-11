class SkillGroupRequirement < ApplicationRecord
  belongs_to :skill_group
  belongs_to :required_group
end
