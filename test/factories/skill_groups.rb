FactoryBot.define do
  factory :skill_group do
    sequence(:external_group_code) { |n| "SG_#{n.to_s.rjust(4, "0")}" }
    sequence(:name) { |n| "Skill Group #{n}" }
    max_skill_level { 2 }
    association :mastery
  end
end
