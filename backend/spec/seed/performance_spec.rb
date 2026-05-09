require "rails_helper"
require "benchmark"

RSpec.describe "Seed script performance", type: :task do
  it "inserts 10,000 employees in under 10 seconds" do
    first_names = %w[Alice Bob Clara David Emma Frank]
    last_names  = %w[Smith Jones Williams Brown Taylor]

    rows = 10_000.times.map do |i|
      {
        full_name:       "#{first_names.sample} #{last_names.sample}",
        job_title:       Faker::Job.title,
        department:      Faker::Commerce.department(max: 1),
        country:         Faker::Address.country,
        salary:          rand(30_000..200_000),
        currency:        "USD",
        employment_type: %w[full_time part_time contract].sample,
        email:           "seed_#{i}_#{SecureRandom.hex(4)}@example.com",
        hired_on:        Faker::Date.backward(days: 1825),
        created_at:      Time.current,
        updated_at:      Time.current
      }
    end

    elapsed = Benchmark.realtime { Employee.insert_all(rows) }

    expect(elapsed).to be < 10
    expect(Employee.count).to eq(10_000)
  end
end
