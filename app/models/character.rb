class Character < ApplicationRecord
  MAX_LEVEL = 150

  belongs_to :race
  has_many :character_masteries, dependent: :destroy
  has_many :masteries, through: :character_masteries
  has_many :character_skills, dependent: :destroy

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
