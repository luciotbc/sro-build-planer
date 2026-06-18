FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "Password1" }
    password_confirmation { "Password1" }
    email_opt_in { false }

    trait :confirmed do
      email_confirmed_at { Time.current }
    end
  end
end
