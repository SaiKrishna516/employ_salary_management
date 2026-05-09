FactoryBot.define do
  factory :employee do
    full_name       { "#{Faker::Name.first_name} #{Faker::Name.last_name}" }
    job_title       { Faker::Job.title }
    department      { Faker::Commerce.department(max: 1) }
    country         { Faker::Address.country }
    salary          { rand(30_000..200_000) }
    currency        { "USD" }
    employment_type { "full_time" }
    email           { Faker::Internet.unique.email }
    hired_on        { Faker::Date.backward(days: 1825) }
  end
end
