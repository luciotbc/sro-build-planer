FactoryBot.define do
  factory :skill_group_requirement do
    association :skill_group
    association :required_group, factory: :skill_group
    required_skill_level { 1 }
  end
end
