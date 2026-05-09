require "yaml"
require "json"

# Load the single source of truth for all Employee option lists.
# Anything that needs these values (model validations, seeds, API, frontend)
# reads from EmployeeOptions — never from hardcoded arrays.
_raw = YAML.load_file(Rails.root.join("config/employee_options.yml")).deep_symbolize_keys

module EmployeeOptions
  # Called once at boot; memoized for the lifetime of the process.
  def self.all
    @all ||= YAML.load_file(
      Rails.root.join("config/employee_options.yml")
    ).deep_symbolize_keys.freeze
  end

  def self.employment_types  = all[:employment_types].map { |e| e[:value] }.freeze
  def self.employment_labels = all[:employment_types].to_h { |e| [e[:value], e[:label]] }.freeze
  def self.currencies        = all[:currencies].freeze
  def self.job_titles        = all[:job_titles].freeze
  def self.departments       = all[:departments].freeze
  def self.countries         = all[:countries].freeze

  # Returns the full hash for JSON serialisation.
  def self.to_json_hash
    {
      employment_types: all[:employment_types],
      currencies:       currencies,
      job_titles:       job_titles,
      departments:      departments,
      countries:        countries
    }
  end
end

# ── Write constants.json to the frontend on every Rails boot ─────────────
# This keeps the frontend in sync without a manual step or extra API call.
frontend_constants = Rails.root.join("../frontend/src/lib/constants.json")

if File.directory?(frontend_constants.dirname)
  File.write(frontend_constants, JSON.pretty_generate(EmployeeOptions.to_json_hash))
  Rails.logger.info "[EmployeeOptions] constants.json written to #{frontend_constants}" if defined?(Rails.logger)
end
