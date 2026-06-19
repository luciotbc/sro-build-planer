FactoryBot.define do
  factory :character do
    sequence(:name) { |n| "Character #{n}" }
    server_level_cap { 110 }
    association :race
    association :user
  end
end
