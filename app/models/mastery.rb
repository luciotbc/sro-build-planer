class Mastery < ApplicationRecord
  belongs_to :race

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :mastery_type, presence: true, inclusion: { in: %w[Weapon Force Physical Magical Support] }
end
