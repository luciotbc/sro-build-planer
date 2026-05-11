class Character < ApplicationRecord
  belongs_to :race
  has_many :character_masteries
  has_many :masteries, through: :character_masteries
end
