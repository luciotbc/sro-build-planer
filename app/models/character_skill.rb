class CharacterSkill < ApplicationRecord
  belongs_to :character
  belongs_to :skill_group
end
