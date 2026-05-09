require "rails_helper"

RSpec.describe "Api::V1::Insights", type: :request do
  before do
    create(:employee, country: "India", job_title: "Engineer", salary: 60_000)
    create(:employee, country: "India", job_title: "Engineer", salary: 100_000)
    create(:employee, country: "India", job_title: "Manager",  salary: 140_000)
  end

  describe "GET /api/v1/insights" do
    it "returns 200" do
      get "/api/v1/insights", params: { country: "India" }
      expect(response).to have_http_status(:ok)
    end

    it "returns overall min/max/avg" do
      get "/api/v1/insights", params: { country: "India" }
      overall = json["overall"]
      expect(overall["min"]).to eq(60_000.0)
      expect(overall["max"]).to eq(140_000.0)
      expect(overall["count"]).to eq(3)
    end

    it "returns job title breakdown" do
      get "/api/v1/insights", params: { country: "India" }
      expect(json["by_job_title"]).to be_an(Array)
    end

    it "returns salary band distribution" do
      get "/api/v1/insights", params: { country: "India" }
      expect(json["salary_bands"]).to be_an(Array)
    end

    it "returns 400 when country param is missing" do
      get "/api/v1/insights"
      expect(response).to have_http_status(:bad_request)
    end

    it "returns countries list endpoint" do
      get "/api/v1/insights/countries"
      expect(response).to have_http_status(:ok)
      expect(json["countries"]).to include("India")
    end
  end
end
