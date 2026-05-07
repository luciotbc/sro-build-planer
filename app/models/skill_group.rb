class SkillGroup < ApplicationRecord
  belongs_to :mastery

  validates :external_group_code, presence: true, uniqueness: true
end
