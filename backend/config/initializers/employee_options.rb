require "yaml"
require "json"

# Load the single source of truth for all Employee option lists.
# Anything that needs these values (model validations, seeds, API, frontend)
# reads from EmployeeOptions — never from hardcoded arrays.
module EmployeeOptions
  # Parsed once at boot and memoized for the lifetime of the process.
  # Re-reading the file on every call is unnecessary I/O.
  def self.all
    @all ||= YAML.load_file(
      Rails.root.join("config/employee_options.yml")
    ).deep_symbolize_keys.freeze
  end

  # Each derived list is also memoized so that model inclusion validators
  # (which call these methods on every save) do not re-allocate arrays.
  def self.employment_types  = @employment_types  ||= all[:employment_types].map { |e| e[:value] }.freeze
  def self.employment_labels = @employment_labels ||= all[:employment_types].to_h { |e| [e[:value], e[:label]] }.freeze
  def self.currencies        = @currencies        ||= all[:currencies].freeze
  def self.job_titles        = @job_titles        ||= all[:job_titles].freeze
  def self.departments       = @departments       ||= all[:departments].freeze
  def self.countries         = @countries         ||= all[:countries].freeze

  # Returns the full hash for JSON serialisation.
  # Builds from the already-memoized methods — no extra array allocation.
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
