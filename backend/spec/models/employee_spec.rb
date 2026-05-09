require "rails_helper"

RSpec.describe Employee, type: :model do

  # ── Validations ─────────────────────────────────────────────────────────
  describe "validations" do

    # Presence — one shoulda one-liner each, no DB hit
    it { is_expected.to validate_presence_of(:full_name) }
    it { is_expected.to validate_presence_of(:job_title) }
    it { is_expected.to validate_presence_of(:department) }
    it { is_expected.to validate_presence_of(:country) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_presence_of(:hired_on) }
    it { is_expected.to validate_presence_of(:salary) }
    it { is_expected.to validate_presence_of(:employment_type) }
    it { is_expected.to validate_presence_of(:currency) }

    # Uniqueness
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }

    # Numericality
    it do
      is_expected.to validate_numericality_of(:salary)
                       .is_greater_than(0)
                       .is_less_than(10_000_000)
    end

    it { is_expected.not_to allow_value(0, -1).for(:salary) }

    # Length
    it { is_expected.to validate_length_of(:full_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:job_title).is_at_most(255) }
    it { is_expected.to validate_length_of(:department).is_at_most(255) }
    it { is_expected.to validate_length_of(:country).is_at_most(255) }

    # Email format — one generated example per bad value, one for a good value
    %w[not-an-email user@ @example.com plaintext].each do |bad_email|
      it { is_expected.not_to allow_value(bad_email).for(:email) }
    end

    it { is_expected.to allow_value("valid.user+tag@example.co.uk").for(:email) }

    # Employment type — valid set and invalid values in two lines
    it { is_expected.to allow_value("full_time", "part_time", "contract").for(:employment_type) }
    it { is_expected.not_to allow_value("freelance", nil).for(:employment_type) }

    # Currency — all valid values in one line, invalids in one line
    it { is_expected.to allow_value(*EmployeeOptions.currencies).for(:currency) }
    it { is_expected.not_to allow_value("BTC", "DOGE", nil).for(:currency) }
  end

  # ── Scopes ───────────────────────────────────────────────────────────────
  # Records are created once per describe block via before; transactional
  # fixtures roll them back after each example with zero extra teardown cost.

  describe ".by_country" do
    before do
      create(:employee, country: "India")
      create(:employee, country: "India")
      create(:employee, country: "USA")
    end

    it "returns only employees from the requested country" do
      expect(Employee.by_country("India").count).to eq(2)
    end

    it "is case-insensitive" do
      expect(Employee.by_country("india").count).to eq(2)
    end
  end

  describe ".by_job_title" do
    before do
      create(:employee, job_title: "Engineer")
      create(:employee, job_title: "Manager")
    end

    it "returns only employees with the matching job title" do
      expect(Employee.by_job_title("Engineer").count).to eq(1)
    end
  end

  describe ".by_department" do
    before do
      create(:employee, department: "Engineering")
      create(:employee, department: "Sales")
    end

    it "filters by department" do
      expect(Employee.by_department("Engineering").count).to eq(1)
    end
  end

  # ── Aggregations ─────────────────────────────────────────────────────────
end
