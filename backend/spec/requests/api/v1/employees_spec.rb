require "rails_helper"

RSpec.describe "Api::V1::Employees", type: :request do
  let(:valid_params) do
    {
      full_name:       "Jane Smith",
      job_title:       "Software Engineer",
      department:      "Engineering",
      country:         "India",
      salary:          90_000,
      currency:        "USD",
      employment_type: "full_time",
      email:           "jane@example.com",
      hired_on:        "2022-01-15"
    }
  end

  # ── INDEX ────────────────────────────────────────────────────────────────
  describe "GET /api/v1/employees" do
    # Basic listing tests need a population of employees.
    context "basic listing" do
      before { create_list(:employee, 5) }

      it "returns 200 with paginated data and meta keys", :aggregate_failures do
        get "/api/v1/employees"
        expect(response).to have_http_status(:ok)
        expect(json["data"].length).to be <= 25
        expect(json["meta"]).to include("current_page", "total_pages", "total_count")
      end
    end

    # Filter tests create only the specific record they need — no shared
    # before block so unrelated employees don't pollute filter assertions.
    context "filtering" do
      it "filters by country" do
        create(:employee, country: "Brazil")
        get "/api/v1/employees", params: { country: "Brazil" }
        expect(json["data"].all? { |e| e["attributes"]["country"] == "Brazil" }).to be true
      end

      it "searches by full_name" do
        create(:employee, full_name: "Unique Person")
        get "/api/v1/employees", params: { search: "Unique" }
        expect(json["data"].any? { |e| e["attributes"]["full_name"].include?("Unique") }).to be true
      end

      it "filters by employment_type" do
        create(:employee, employment_type: "contract")
        get "/api/v1/employees", params: { employment_type: "contract" }
        expect(json["data"].all? { |e| e["attributes"]["employment_type"] == "contract" }).to be true
      end

      it "filters by department" do
        create(:employee, department: "Engineering")
        get "/api/v1/employees", params: { department: "Engineering" }
        expect(json["data"].all? { |e| e["attributes"]["department"] == "Engineering" }).to be true
      end
    end
  end

  # ── SHOW ─────────────────────────────────────────────────────────────────
  describe "GET /api/v1/employees/:id" do
    let(:employee) { create(:employee) }

    # Merged into one request — saves a full HTTP round-trip + DB create.
    it "returns 200 with the correct id and all expected attributes", :aggregate_failures do
      get "/api/v1/employees/#{employee.id}"
      expect(response).to have_http_status(:ok)
      expect(json["data"]["id"].to_i).to eq(employee.id)
      expect(json["data"]["attributes"]).to include(
        "full_name", "job_title", "department", "country", "salary", "employment_type", "email"
      )
    end

    it "returns 404 with an error key for a missing employee", :aggregate_failures do
      get "/api/v1/employees/999999"
      expect(response).to have_http_status(:not_found)
      expect(json).to have_key("error")
    end
  end

  # ── CREATE ───────────────────────────────────────────────────────────────
  describe "POST /api/v1/employees" do
    # Happy path: count change, status, and response body in one request.
    it "creates an employee and returns 201 with the new record", :aggregate_failures do
      expect {
        post "/api/v1/employees", params: { employee: valid_params }
      }.to change(Employee, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json["data"]["attributes"]["full_name"]).to eq("Jane Smith")
    end

    context "with invalid params — all expect 422 with errors key" do
      after { expect(response).to have_http_status(:unprocessable_content) }

      it "rejects a negative salary" do
        post "/api/v1/employees", params: { employee: valid_params.merge(salary: -1) }
        expect(json).to have_key("errors")
      end

      it "rejects a missing full_name" do
        post "/api/v1/employees", params: { employee: valid_params.except(:full_name) }
      end

      it "rejects a missing email" do
        post "/api/v1/employees", params: { employee: valid_params.except(:email) }
      end

      it "rejects an invalid employment_type" do
        post "/api/v1/employees", params: { employee: valid_params.merge(employment_type: "freelance") }
      end

      it "rejects a duplicate email" do
        create(:employee, email: "jane@example.com")
        post "/api/v1/employees", params: { employee: valid_params }
      end
    end
  end

  # ── UPDATE ───────────────────────────────────────────────────────────────
  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee) }

    # Both field updates in a single PATCH + reload — saves 1 request + 1 create.
    it "updates fields and returns 200", :aggregate_failures do
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { salary: 150_000, job_title: "Principal Engineer" } }
      expect(response).to have_http_status(:ok)
      employee.reload
      expect(employee.salary).to eq(150_000)
      expect(employee.job_title).to eq("Principal Engineer")
    end

    it "returns 422 with errors for an invalid salary", :aggregate_failures do
      patch "/api/v1/employees/#{employee.id}", params: { employee: { salary: -500 } }
      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to have_key("errors")
    end

    it "returns 404 for a missing employee" do
      patch "/api/v1/employees/999999", params: { employee: { salary: 100_000 } }
      expect(response).to have_http_status(:not_found)
    end
  end

  # ── DELETE ───────────────────────────────────────────────────────────────
  describe "DELETE /api/v1/employees/:id" do
    let!(:employee) { create(:employee) }

    # Merged count change + status + empty body into one example.
    it "deletes the employee, returns 204 with an empty body", :aggregate_failures do
      expect {
        delete "/api/v1/employees/#{employee.id}"
      }.to change(Employee, :count).by(-1)
      expect(response).to have_http_status(:no_content)
      expect(response.body).to be_empty
    end

    it "returns 404 when employee does not exist" do
      delete "/api/v1/employees/999999"
      expect(response).to have_http_status(:not_found)
    end
  end
end
