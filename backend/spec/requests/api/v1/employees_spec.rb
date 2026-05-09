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

  # --- INDEX ---
  describe "GET /api/v1/employees" do
    before { create_list(:employee, 5) }

    it "returns 200" do
      get "/api/v1/employees"
      expect(response).to have_http_status(:ok)
    end

    it "returns paginated employees" do
      get "/api/v1/employees"
      expect(json["data"].length).to be <= 25
      expect(json).to have_key("meta")
    end

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

    it "returns meta with pagination info" do
      get "/api/v1/employees"
      expect(json["meta"]).to include("current_page", "total_pages", "total_count")
    end
  end

  # --- SHOW ---
  describe "GET /api/v1/employees/:id" do
    let(:employee) { create(:employee) }

    it "returns 200 with the employee" do
      get "/api/v1/employees/#{employee.id}"
      expect(response).to have_http_status(:ok)
      expect(json["data"]["id"].to_i).to eq(employee.id)
    end

    it "returns the correct attributes" do
      get "/api/v1/employees/#{employee.id}"
      attrs = json["data"]["attributes"]
      expect(attrs).to include(
        "full_name", "job_title", "department",
        "country", "salary", "employment_type", "email"
      )
    end

    it "returns 404 for a missing employee" do
      get "/api/v1/employees/999999"
      expect(response).to have_http_status(:not_found)
      expect(json).to have_key("error")
    end
  end

  # --- CREATE ---
  describe "POST /api/v1/employees" do
    it "creates an employee and returns 201" do
      expect {
        post "/api/v1/employees", params: { employee: valid_params }
      }.to change(Employee, :count).by(1)
      expect(response).to have_http_status(:created)
    end

    it "returns the created employee in the response" do
      post "/api/v1/employees", params: { employee: valid_params }
      expect(json["data"]["attributes"]["full_name"]).to eq("Jane Smith")
    end

    it "returns 422 with validation errors for negative salary" do
      post "/api/v1/employees", params: { employee: valid_params.merge(salary: -1) }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to have_key("errors")
    end

    it "returns 422 when full_name is missing" do
      post "/api/v1/employees", params: { employee: valid_params.except(:full_name) }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when email is missing" do
      post "/api/v1/employees", params: { employee: valid_params.except(:email) }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for duplicate email" do
      post "/api/v1/employees", params: { employee: valid_params }
      post "/api/v1/employees", params: { employee: valid_params.merge(full_name: "Other Person") }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for invalid employment_type" do
      post "/api/v1/employees", params: { employee: valid_params.merge(employment_type: "freelance") }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # --- UPDATE ---
  describe "PATCH /api/v1/employees/:id" do
    let(:employee) { create(:employee) }

    it "updates the employee salary and returns 200" do
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { salary: 150_000 } }
      expect(response).to have_http_status(:ok)
      expect(employee.reload.salary).to eq(150_000)
    end

    it "updates the job title" do
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { job_title: "Principal Engineer" } }
      expect(employee.reload.job_title).to eq("Principal Engineer")
    end

    it "returns 422 for invalid salary on update" do
      patch "/api/v1/employees/#{employee.id}",
            params: { employee: { salary: -500 } }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to have_key("errors")
    end

    it "returns 404 for a missing employee" do
      patch "/api/v1/employees/999999",
            params: { employee: { salary: 100_000 } }
      expect(response).to have_http_status(:not_found)
    end
  end

  # --- DELETE ---
  describe "DELETE /api/v1/employees/:id" do
    let!(:employee) { create(:employee) }

    it "deletes the employee and returns 204" do
      expect {
        delete "/api/v1/employees/#{employee.id}"
      }.to change(Employee, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 when employee does not exist" do
      delete "/api/v1/employees/999999"
      expect(response).to have_http_status(:not_found)
    end

    it "returns an empty body on successful delete" do
      delete "/api/v1/employees/#{employee.id}"
      expect(response.body).to be_empty
    end
  end
end
