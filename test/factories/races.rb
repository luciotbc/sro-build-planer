FactoryBot.define do
  factory :race do
    sequence(:external_id) { |n| n }
    sequence(:name) { |n| "Race #{n}" }

    trait :chinese do
      external_id { 1 }
      name { "Chinese" }
    end

    trait :european do
      external_id { 2 }
      name { "European" }
    end
  end
end
