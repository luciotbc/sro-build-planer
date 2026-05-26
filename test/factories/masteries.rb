FactoryBot.define do
  factory :mastery do
    sequence(:external_id) { |n| 10_000 + n }
    sequence(:name) { |n| "Mastery #{n}" }
    mastery_type { "Weapon" }
    association :race

    trait :blade do
      external_id { 257 }
      name { "Blade" }
      mastery_type { "Weapon" }
    end

    trait :spear do
      external_id { 258 }
      name { "Spear" }
      mastery_type { "Weapon" }
    end

    trait :cold do
      external_id { 273 }
      name { "Cold" }
      mastery_type { "Force" }
    end

    trait :warrior do
      external_id { 513 }
      name { "Warrior" }
      mastery_type { "Physical" }
    end

    trait :wizard do
      external_id { 514 }
      name { "Wizard" }
      mastery_type { "Magical" }
    end
  end
end
