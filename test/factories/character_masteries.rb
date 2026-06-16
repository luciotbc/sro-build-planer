FactoryBot.define do
  factory :character_mastery do
    association :character
    association :mastery
    current_mastery_level { 0 }
    target_mastery_level { 0 }
  end
end
