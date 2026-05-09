require "rails_helper"

RSpec.describe InsightsQuery do
  describe ".call" do
    before do
      create(:employee, country: "India", job_title: "Engineer",  salary: 50_000)
      create(:employee, country: "India", job_title: "Engineer",  salary: 90_000)
      create(:employee, country: "India", job_title: "Manager",   salary: 120_000)
      create(:employee, country: "USA",   job_title: "Engineer",  salary: 200_000)
    end

    subject(:result) { described_class.call(country: "India") }

    it "returns min salary for the country" do
      expect(result[:overall][:min]).to eq(50_000.0)
    end

    it "returns max salary for the country" do
      expect(result[:overall][:max]).to eq(120_000.0)
    end

    it "returns average salary for the country" do
      expect(result[:overall][:avg].round).to eq(86_667)
    end

    it "returns total headcount for the country" do
      expect(result[:overall][:count]).to eq(3)
    end

    it "excludes employees from other countries" do
      expect(result[:overall][:count]).not_to eq(4)
    end

    it "returns per-job-title breakdown" do
      engineer_row = result[:by_job_title].find { |r| r[:job_title] == "Engineer" }
      expect(engineer_row[:avg].round).to eq(70_000)
      expect(engineer_row[:count]).to eq(2)
    end

    it "returns salary band distribution" do
      expect(result[:salary_bands]).to be_an(Array)
      expect(result[:salary_bands].first).to have_key(:band)
      expect(result[:salary_bands].first).to have_key(:count)
    end

    it "returns an empty result for a country with no employees" do
      result = described_class.call(country: "Antarctica")
      expect(result[:overall][:count]).to eq(0)
    end
  end

  describe ".countries" do
    it "returns a distinct sorted list of countries" do
      create(:employee, country: "India")
      create(:employee, country: "USA")
      create(:employee, country: "India")

      countries = InsightsQuery.countries
      expect(countries).to eq(["India", "USA"])
      expect(countries.uniq).to eq(countries)
    end
  end
end
