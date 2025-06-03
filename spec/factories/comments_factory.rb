# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs(number: 3).join("\n\n") }
    association :post
  end
end
