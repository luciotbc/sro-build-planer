class Race < ApplicationRecord
  has_many :masteries, dependent: :destroy
  has_many :characters, dependent: :destroy

  validates :external_id, presence: true, uniqueness: true
  validates :name, presence: true
end
