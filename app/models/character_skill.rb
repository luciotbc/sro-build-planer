class CharacterSkill < ApplicationRecord
  belongs_to :character
  belongs_to :skill_group

  validates :skill_group_id, uniqueness: { scope: :character_id }
end
