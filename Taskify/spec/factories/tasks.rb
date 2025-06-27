FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph(sentence_count: 2) }
    status { 'pending' }
    priority { 'medium' }
    association :user
    assignee { nil }

    trait :assigned do
      association :assignee, factory: :user
    end

    trait :completed do
      status { 'completed' }
    end

    trait :high_priority do
      priority { 'high' }
    end

    trait :with_due_date do
      due_date { 3.days.from_now }
    end
  end
end 