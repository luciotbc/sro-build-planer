class Skill < ApplicationRecord
  belongs_to :skill_group

  validates :external_id, presence: true, uniqueness: true
  validates :external_skill_code, presence: true, uniqueness: true
  validates :skill_level, presence: true
end
