FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    association :user
  end

  factory :post_with_only_filter, class: 'PostWithOnlyFilter', parent: :post
  factory :post_with_ignore_filter, class: 'PostWithIgnoreFilter', parent: :post
end
