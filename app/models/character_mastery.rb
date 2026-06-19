class CharacterMastery < ApplicationRecord
  belongs_to :character, inverse_of: :character_masteries
  belongs_to :mastery

  after_save :recompute_character_levels
  after_destroy :recompute_character_levels

  validates :mastery_id, uniqueness: { scope: :character_id }
  validates :current_mastery_level,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            },
            allow_nil: true
  validates :target_mastery_level,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            },
            allow_nil: true
  validate :mastery_levels_within_server_cap

  private

  def mastery_levels_within_server_cap
    cap = character&.server_level_cap
    return unless cap

    if current_mastery_level && current_mastery_level > cap
      errors.add(:current_mastery_level, "must be less than or equal to #{cap}")
    end

    if target_mastery_level && target_mastery_level > cap
      errors.add(:target_mastery_level, "must be less than or equal to #{cap}")
    end
  end

  def recompute_character_levels
    character.recompute_levels!
  end
end
