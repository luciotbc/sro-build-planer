FactoryBot.define do
  factory :character do
    sequence(:name) { |n| "Character #{n}" }
    current_level { 0 }
    target_level { 0 }
    association :race
  end
end
