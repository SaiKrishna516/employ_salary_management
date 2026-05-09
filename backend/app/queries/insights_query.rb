# Encapsulates all salary insights SQL logic.
# PostgreSQL-safe: uses .to_a.first for aggregate-only SELECTs (avoids the
# ORDER BY id LIMIT 1 that ActiveRecord's .first adds, which PG rejects when
# no non-aggregated columns are present), and Arel.sql for all raw SQL strings.
class InsightsQuery
  BAND_SIZE = 20_000

  def self.call(country:)
    new(country: country).call
  end

  def self.countries
    Employee.distinct.order(:country).pluck(:country)
  end

  def initialize(country:)
    @scope = Employee.by_country(country)
  end

  def call
    {
      overall:      overall_stats,
      by_job_title: by_job_title_breakdown,
      salary_bands: salary_band_distribution
    }
  end

  private

  # Single aggregate query — no GROUP BY, no ORDER BY, fully PG-safe.
  # .to_a.first is used instead of .first to prevent ActiveRecord from
  # appending ORDER BY "employees"."id" ASC LIMIT 1 which PG rejects on
  # aggregate-only SELECT statements.
  def overall_stats
    return empty_stats if @scope.empty?

    row = @scope
      .select(Arel.sql(
        "MIN(salary)  AS min_salary,
         MAX(salary)  AS max_salary,
         AVG(salary)  AS avg_salary,
         COUNT(*)     AS employee_count"
      ))
      .to_a
      .first

    {
      min:   row.min_salary.to_f,
      max:   row.max_salary.to_f,
      avg:   row.avg_salary.to_f,
      count: row.employee_count.to_i
    }
  end

  # GROUP BY query — each column in SELECT is either grouped or aggregated,
  # which is valid in PG. Arel.sql used for ORDER BY to prevent AR quoting.
  def by_job_title_breakdown
    @scope
      .group(:job_title)
      .select(Arel.sql(
        "job_title,
         MIN(salary) AS min_salary,
         MAX(salary) AS max_salary,
         AVG(salary) AS avg_salary,
         COUNT(*)    AS employee_count"
      ))
      .order(Arel.sql("AVG(salary) DESC"))
      .map do |row|
        {
          job_title: row.job_title,
          min:       row.min_salary.to_f,
          max:       row.max_salary.to_f,
          avg:       row.avg_salary.to_f,
          count:     row.employee_count.to_i
        }
      end
  end

  # Single GROUP BY query using FLOOR bucketing — O(1) queries regardless of
  # salary range, replaces a while loop that would fire O(n) queries.
  # Only bands with at least one employee are returned.
  def salary_band_distribution
    return [] if @scope.empty?

    @scope
      .group(Arel.sql("FLOOR(salary / #{BAND_SIZE}) * #{BAND_SIZE}"))
      .select(Arel.sql(
        "FLOOR(salary / #{BAND_SIZE}) * #{BAND_SIZE} AS band_start,
         COUNT(*) AS employee_count"
      ))
      .order(Arel.sql("band_start"))
      .map do |row|
        band_start = row.band_start.to_f
        {
          band:  "#{format_band(band_start)}–#{format_band(band_start + BAND_SIZE)}",
          count: row.employee_count.to_i
        }
      end
  end

  def format_band(amount)
    "$#{(amount / 1_000).to_i}k"
  end

  def empty_stats
    { min: 0, max: 0, avg: 0, count: 0 }
  end
end
