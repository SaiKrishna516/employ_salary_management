class Employee < ApplicationRecord
  # Option lists live in config/employee_options.yml — accessed via EmployeeOptions module.
  # Do NOT redefine them here; use EmployeeOptions.employment_types / .currencies directly.

  validates :full_name,       presence: true
  validates :job_title,       presence: true
  validates :department,      presence: true
  validates :country,         presence: true
  validates :email,           presence: true, uniqueness: { case_sensitive: false }
  validates :hired_on,        presence: true
  validates :salary,          numericality: { greater_than: 0, less_than: 10_000_000 }
  validates :employment_type, inclusion: { in: -> { EmployeeOptions.employment_types } }
  validates :currency,        inclusion: { in: -> { EmployeeOptions.currencies } }

  # Columns the API is allowed to sort by. Anything outside this list falls
  # back to the default (id asc) — prevents SQL injection via sort param.
  SORTABLE_COLUMNS = %w[id full_name salary hired_on department country job_title].freeze

  scope :by_country,    ->(c) { where("LOWER(country) = ?", c.downcase) }
  scope :by_job_title,  ->(t) { where(job_title: t) }
  scope :by_department, ->(d) { where(department: d) }

  # Apply sort from request params. Safe against arbitrary column injection.
  scope :sorted, ->(col = nil, dir = nil) {
    column    = SORTABLE_COLUMNS.include?(col.to_s) ? col.to_s : "id"
    direction = %w[asc desc].include?(dir.to_s.downcase) ? dir.to_s.downcase : "asc"
    order(Arel.sql("#{column} #{direction}"))
  }

  # Entry point for controller — delegates filter logic to the query object.
  def self.filter(params = {})
    EmployeeFilter.apply(all, params)
  end

  def self.salary_stats
    {
      min:   minimum(:salary).to_f,
      max:   maximum(:salary).to_f,
      avg:   average(:salary).to_f,
      count: count
    }
  end
end
