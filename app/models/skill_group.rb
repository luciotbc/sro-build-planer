class SkillGroup < ApplicationRecord
  belongs_to :mastery
  has_many :skills, dependent: :destroy

  validates :external_group_code, presence: true, uniqueness: true
end
