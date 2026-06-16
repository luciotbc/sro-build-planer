FactoryBot.define do
  factory :skill do
    sequence(:external_id) { |n| 20_000 + n }
    sequence(:external_skill_code) { |n| "SKILL_#{n.to_s.rjust(4, "0")}" }
    skill_level { 1 }
    sp_cost { 0 }
    mastery_level_req { 1 }
    association :skill_group
  end
end
