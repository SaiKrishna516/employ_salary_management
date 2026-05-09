class Employee < ApplicationRecord
  EMPLOYMENT_TYPES = %w[full_time part_time contract].freeze
  CURRENCIES       = %w[USD EUR GBP INR AUD CAD].freeze

  validates :full_name,       presence: true
  validates :job_title,       presence: true
  validates :department,      presence: true
  validates :country,         presence: true
  validates :email,           presence: true, uniqueness: { case_sensitive: false }
  validates :hired_on,        presence: true
  validates :salary,          numericality: { greater_than: 0, less_than: 10_000_000 }
  validates :employment_type, inclusion: { in: EMPLOYMENT_TYPES }
  validates :currency,        inclusion: { in: CURRENCIES }

  scope :by_country,    ->(c) { where("LOWER(country) = ?", c.downcase) }
  scope :by_job_title,  ->(t) { where(job_title: t) }
  scope :by_department, ->(d) { where(department: d) }

  def self.salary_stats
    {
      min:   minimum(:salary).to_f,
      max:   maximum(:salary).to_f,
      avg:   average(:salary).to_f,
      count: count
    }
  end
end
