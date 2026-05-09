require "rails_helper"

RSpec.describe Employee, type: :model do

  describe "validations" do
    it { should validate_presence_of(:full_name) }
    it { should validate_presence_of(:job_title) }
    it { should validate_presence_of(:department) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:hired_on) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it { should validate_numericality_of(:salary)
                  .is_greater_than(0)
                  .is_less_than(10_000_000) }

    it "is invalid with an unknown employment_type" do
      employee = build(:employee, employment_type: "freelance")
      expect(employee).not_to be_valid
      expect(employee.errors[:employment_type]).to be_present
    end

    it "is valid with employment_type full_time" do
      expect(build(:employee, employment_type: "full_time")).to be_valid
    end

    it "is valid with employment_type part_time" do
      expect(build(:employee, employment_type: "part_time")).to be_valid
    end

    it "is valid with employment_type contract" do
      expect(build(:employee, employment_type: "contract")).to be_valid
    end
  end

  describe ".by_country" do
    it "returns employees in the specified country only" do
      create(:employee, country: "India")
      create(:employee, country: "India")
      create(:employee, country: "USA")
      expect(Employee.by_country("India").count).to eq(2)
    end

    it "is case-insensitive" do
      create(:employee, country: "India")
      expect(Employee.by_country("india").count).to eq(1)
    end
  end

  describe ".by_job_title" do
    it "returns employees with the specified job title" do
      create(:employee, job_title: "Engineer")
      create(:employee, job_title: "Manager")
      expect(Employee.by_job_title("Engineer").count).to eq(1)
    end
  end

  describe ".by_department" do
    it "filters by department" do
      create(:employee, department: "Engineering")
      create(:employee, department: "Sales")
      expect(Employee.by_department("Engineering").count).to eq(1)
    end
  end

  describe ".salary_stats" do
    it "returns min, max, average, and count" do
      create(:employee, country: "India", salary: 40_000)
      create(:employee, country: "India", salary: 80_000)
      create(:employee, country: "India", salary: 120_000)

      stats = Employee.by_country("India").salary_stats

      expect(stats[:min]).to eq(40_000)
      expect(stats[:max]).to eq(120_000)
      expect(stats[:avg].round).to eq(80_000)
      expect(stats[:count]).to eq(3)
    end
  end
end
