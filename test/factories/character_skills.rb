FactoryBot.define do
  factory :character_skill do
    association :character
    association :skill_group
    current_skill_level { 0 }
    target_skill_level { 0 }
  end
end
