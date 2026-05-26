FactoryBot.define do
  factory :skill_series do
    sequence(:title) { |n| "Series #{n}" }
    row_position { 1 }
    association :mastery
  end
end
