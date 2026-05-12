class Character < ApplicationRecord
  belongs_to :race
  has_many :character_masteries, dependent: :destroy
  has_many :masteries, through: :character_masteries
  has_many :character_skills, dependent: :destroy

  validates :name, presence: true
end
