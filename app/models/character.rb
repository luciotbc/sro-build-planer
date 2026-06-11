class Character < ApplicationRecord
  MAX_LEVEL = 150

  # Server level caps selectable when creating a character (design: cc-caps).
  LEVEL_CAPS = {
    90 => "Classic",
    100 => "Legacy",
    110 => "Standard",
    120 => "High",
    130 => "Extreme"
  }.freeze

  belongs_to :race
  belongs_to :user, optional: true, inverse_of: :characters
  has_many :character_masteries, dependent: :destroy, inverse_of: :character
  has_many :masteries, through: :character_masteries
  has_many :character_skills, dependent: :destroy, inverse_of: :character

  validates :name, presence: true
  validates :current_level,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_LEVEL
            },
            allow_nil: true
  validates :target_level,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0,
              less_than_or_equal_to: MAX_LEVEL
            },
            allow_nil: true
end
