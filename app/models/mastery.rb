class Mastery < ApplicationRecord
  belongs_to :race
  has_many :skill_groups, dependent: :destroy
  has_many :skill_series, dependent: :destroy
  has_many :character_masteries, dependent: :destroy
  has_many :characters, through: :character_masteries

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :mastery_type,
            presence: true,
            inclusion: {
              in: %w[Weapon Force Physical Magical Support]
            }
end
