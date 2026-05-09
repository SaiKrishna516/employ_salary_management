require "rails_helper"

RSpec.describe InsightsQuery do
  describe ".call" do
    before do
      create(:employee, country: "India", job_title: "Engineer", salary: 50_000)
      create(:employee, country: "India", job_title: "Engineer", salary: 90_000)
      create(:employee, country: "India", job_title: "Manager",  salary: 120_000)
      create(:employee, country: "USA",   job_title: "Engineer", salary: 200_000)
    end

    # Named subject — memoized within the example, so all expectations below
    # share a single query call instead of re-running for each separate it block.
    subject(:result) { described_class.call(country: "India") }

    # All overall-stat assertions in one example: saves 4 redundant query calls.
    it "returns correct overall stats for the country (excluding other countries)", :aggregate_failures do
      expect(result[:overall][:min]).to           eq(50_000.0)
      expect(result[:overall][:max]).to           eq(120_000.0)
      expect(result[:overall][:avg].round).to     eq(86_667)
      expect(result[:overall][:count]).to         eq(3)   # USA employee excluded
    end

    it "returns correct per-job-title breakdown", :aggregate_failures do
      engineer = result[:by_job_title].find { |r| r[:job_title] == "Engineer" }
      expect(engineer[:avg].round).to eq(70_000)
      expect(engineer[:count]).to     eq(2)
    end

    it "returns salary band distribution with band and count keys", :aggregate_failures do
      expect(result[:salary_bands]).to        be_an(Array)
      expect(result[:salary_bands].first).to  have_key(:band)
      expect(result[:salary_bands].first).to  have_key(:count)
    end

    it "returns empty stats for a country with no employees" do
      empty = described_class.call(country: "Antarctica")
      expect(empty[:overall][:count]).to eq(0)
    end
  end

  describe ".countries" do
    before do
      create(:employee, country: "India")
      create(:employee, country: "USA")
      create(:employee, country: "India")  # duplicate — should not appear twice
    end

    subject(:countries) { described_class.countries }

    it "returns a distinct, sorted list", :aggregate_failures do
      expect(countries).to eq(["India", "USA"])
      expect(countries.uniq).to eq(countries)
    end
  end
end
