class LevelDatum < ApplicationRecord
  validates :level, presence: true, uniqueness: true
end
