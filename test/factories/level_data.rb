FactoryBot.define do
  factory :level_datum do
    sequence(:level) { |n| n }
    xp_required { 1000 }
    sp_gained { 3 }
    sp_cumulative { 3 }
  end
end
