class Character < ApplicationRecord
  MAX_LEVEL = 150
  SERVER_LEVEL_CAPS = [90, 100, 110, 120, 130].freeze

  belongs_to :race
  belongs_to :user
  has_many :character_masteries, dependent: :destroy, inverse_of: :character
  has_many :masteries, through: :character_masteries
  has_many :character_skills, dependent: :destroy, inverse_of: :character

  # Permanent public token for the read-only shared-build page (task 021).
  before_create { self.share_token ||= SecureRandom.uuid }

  validates :name, presence: true
  validates :share_token, uniqueness: true, allow_nil: true
  validates :server_level_cap, inclusion: { in: SERVER_LEVEL_CAPS }
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

  def recompute_levels!
    max_current = character_masteries.maximum(:current_mastery_level) || 0
    max_target = character_masteries.maximum(:target_mastery_level) || 0
    update_columns(current_level: max_current, target_level: max_target)
  end
end
