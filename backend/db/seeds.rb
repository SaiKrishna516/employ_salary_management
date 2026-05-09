require "benchmark"

puts "Clearing existing employees..."
Employee.delete_all   # fast truncate — no callbacks

first_names = File.readlines(Rails.root.join("db/first_names.txt")).map(&:strip).reject(&:empty?)
last_names  = File.readlines(Rails.root.join("db/last_names.txt")).map(&:strip).reject(&:empty?)

raise "db/first_names.txt is empty — cannot seed" if first_names.empty?
raise "db/last_names.txt is empty — cannot seed"  if last_names.empty?

COUNTRIES        = ["India", "USA", "UK", "Canada", "Australia", "Germany", "France", "Brazil", "Japan", "Singapore"].freeze
JOB_TITLES       = ["Software Engineer", "Senior Engineer", "Engineering Manager", "Product Manager",
                     "Data Analyst", "Data Scientist", "HR Manager", "Finance Analyst",
                     "Marketing Lead", "Operations Manager", "Sales Executive", "Designer"].freeze
DEPARTMENTS      = ["Engineering", "Product", "Data", "HR", "Finance", "Marketing", "Operations", "Sales", "Design"].freeze
EMPLOYMENT_TYPES = ["full_time", "part_time", "contract"].freeze
CURRENCIES       = ["USD", "EUR", "GBP", "INR", "AUD", "CAD"].freeze

BATCH_SIZE  = 1_000
TOTAL       = 10_000

puts "Seeding #{TOTAL} employees in batches of #{BATCH_SIZE}..."

elapsed = Benchmark.realtime do
  (TOTAL / BATCH_SIZE).times do |batch|
    rows = BATCH_SIZE.times.map do |i|
      idx = batch * BATCH_SIZE + i
      {
        full_name:       "#{first_names.sample} #{last_names.sample}",
        job_title:       JOB_TITLES.sample,
        department:      DEPARTMENTS.sample,
        country:         COUNTRIES.sample,
        salary:          rand(30_000..250_000),
        currency:        CURRENCIES.sample,
        employment_type: EMPLOYMENT_TYPES.sample,
        email:           "employee_#{idx}_#{SecureRandom.hex(4)}@company.com",
        hired_on:        rand(1825).days.ago.to_date,
        created_at:      Time.current,
        updated_at:      Time.current
      }
    end

    Employee.insert_all(rows)
    print "."
  end
end

puts "\nDone. #{Employee.count} employees seeded in #{elapsed.round(2)}s"
