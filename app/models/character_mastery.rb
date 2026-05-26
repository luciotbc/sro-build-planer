class CharacterMastery < ApplicationRecord
  belongs_to :character
  belongs_to :mastery

  validates :mastery_id, uniqueness: { scope: :character_id }
  validates :current_mastery_level,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: Character::MAX_LEVEL
            },
            allow_nil: true
  validates :target_mastery_level,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: Character::MAX_LEVEL
            },
            allow_nil: true
end
