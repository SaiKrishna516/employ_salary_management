class EmployeeSerializer
  include JSONAPI::Serializer

  attributes :full_name, :job_title, :department, :country,
             :salary, :currency, :employment_type, :email,
             :hired_on, :created_at, :updated_at
end
