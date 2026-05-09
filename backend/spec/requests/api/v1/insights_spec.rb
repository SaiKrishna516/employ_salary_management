require "rails_helper"

RSpec.describe "Api::V1::Insights", type: :request do
  # ── /insights (country-scoped) ───────────────────────────────────────────
  describe "GET /api/v1/insights" do
    context "with data present" do
      # before scoped here — the 400 and countries tests don't pay this cost.
      before do
        create(:employee, country: "India", job_title: "Engineer", salary: 60_000)
        create(:employee, country: "India", job_title: "Engineer", salary: 100_000)
        create(:employee, country: "India", job_title: "Manager",  salary: 140_000)
      end

      # Three structural checks in one request instead of three.
      it "returns 200 with overall stats, breakdown, and salary bands", :aggregate_failures do
        get "/api/v1/insights", params: { country: "India" }
        expect(response).to have_http_status(:ok)
        expect(json["overall"]["min"]).to   eq(60_000.0)
        expect(json["overall"]["max"]).to   eq(140_000.0)
        expect(json["overall"]["count"]).to eq(3)
        expect(json["by_job_title"]).to be_an(Array)
        expect(json["salary_bands"]).to  be_an(Array)
      end
    end

    it "returns 400 when country param is missing" do
      get "/api/v1/insights"
      expect(response).to have_http_status(:bad_request)
    end
  end

  # ── /insights/countries ──────────────────────────────────────────────────
  describe "GET /api/v1/insights/countries" do
    before { create(:employee, country: "India") }

    it "returns 200 with a list that includes seeded countries", :aggregate_failures do
      get "/api/v1/insights/countries"
      expect(response).to have_http_status(:ok)
      expect(json["countries"]).to include("India")
    end
  end
end
