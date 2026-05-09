class Mastery < ApplicationRecord
  belongs_to :race
  has_many :skill_groups, foreign_key: :mastery_id, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :mastery_type,
            presence: true,
            inclusion: {
              in: %w[Weapon Force Physical Magical Support]
            }
end
