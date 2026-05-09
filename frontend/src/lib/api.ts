import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  headers: { "Content-Type": "application/json" },
});

// ── Types ──────────────────────────────────────────────────────────────────

export interface Employee {
  id: number;
  full_name: string;
  job_title: string;
  department: string;
  country: string;
  salary: number;
  currency: string;
  employment_type: "full_time" | "part_time" | "contract";
  email: string;
  hired_on: string;
}

export interface PaginatedResponse<T> {
  data: Array<{ id: string; attributes: T }>;
  meta: {
    current_page: number;
    total_pages: number;
    total_count: number;
  };
}

export interface InsightsResponse {
  overall: { min: number; max: number; avg: number; count: number };
  by_job_title: Array<{
    job_title: string;
    min: number;
    max: number;
    avg: number;
    count: number;
  }>;
  salary_bands: Array<{ band: string; count: number }>;
}

// ── Employee API calls ────────────────────────────────────────────────────

export interface EmployeeFilters {
  page?: number;
  per_page?: number;
  search?: string;
  country?: string;
  employment_type?: string;
  department?: string;
  sort?: string;
  direction?: "asc" | "desc";
}

export const employeeApi = {
  list: (filters: EmployeeFilters = {}) =>
    api.get<PaginatedResponse<Employee>>("/employees", { params: filters }),

  get: (id: number) =>
    api.get<{ data: { id: string; attributes: Employee } }>(`/employees/${id}`),

  create: (data: Omit<Employee, "id">) =>
    api.post<{ data: { id: string; attributes: Employee } }>("/employees", {
      employee: data,
    }),

  update: (id: number, data: Partial<Omit<Employee, "id">>) =>
    api.patch<{ data: { id: string; attributes: Employee } }>(
      `/employees/${id}`,
      { employee: data }
    ),

  delete: (id: number) => api.delete(`/employees/${id}`),
};

// ── Insights API calls ────────────────────────────────────────────────────

export const insightsApi = {
  countries: () =>
    api.get<{ countries: string[] }>("/insights/countries"),

  get: (country: string) =>
    api.get<InsightsResponse>("/insights", { params: { country } }),
};
