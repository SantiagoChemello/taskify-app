FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Name.name }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { 'task_doer' }

    trait :admin do
      role { 'admin' }
    end

    trait :task_maker do
      role { 'task_maker' }
    end

    trait :task_doer do
      role { 'task_doer' }
    end
  end
end 