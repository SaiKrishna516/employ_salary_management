require "simplecov"
SimpleCov.start "rails" do
  add_filter "/bin/"
  add_filter "/db/"
  add_filter "/spec/" # Ignore specs themselves
end

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rspec/rails"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# Auto-supply a valid FactoryBot subject for model specs so that
# shoulda-matchers can satisfy NOT NULL DB constraints when testing
# uniqueness validators without an explicit subject in each spec.
RSpec.shared_context "factory subject" do
  subject { build(described_class.model_name.singular.to_sym) }
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
  config.include_context "factory subject", type: :model
end

Shoulda::Matchers.configure do |config|
  config.integrate { |with|
    with.test_framework :rspec
    with.library :rails
  }
end
