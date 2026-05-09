# Encapsulates all Employee filtering logic.
# Adding a new filter = one line in FILTERS. Controller stays untouched.
#
# Usage:
#   EmployeeFilter.apply(Employee.all, params)  # => ActiveRecord::Relation
class EmployeeFilter
  FILTERS = {
    country:         ->(rel, val) { rel.by_country(val) },
    job_title:       ->(rel, val) { rel.by_job_title(val) },
    department:      ->(rel, val) { rel.by_department(val) },
    employment_type: ->(rel, val) { rel.where(employment_type: val) },
    search:          ->(rel, val) { rel.where("LOWER(full_name) LIKE ?", "%#{val.downcase}%") }
  }.freeze

  def self.apply(relation, params)
    new(relation, params).call
  end

  def initialize(relation, params)
    @relation = relation
    @params   = params.to_h.with_indifferent_access
  end

  def call
    FILTERS.reduce(@relation) do |rel, (key, filter)|
      value = @params[key]
      value.present? ? filter.call(rel, value) : rel
    end
  end
end
