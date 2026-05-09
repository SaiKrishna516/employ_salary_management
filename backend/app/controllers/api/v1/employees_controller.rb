module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: [:show, :update, :destroy]

      def index
        employees = Employee.all
        employees = employees.by_country(params[:country])                        if params[:country].present?
        employees = employees.by_job_title(params[:job_title])                    if params[:job_title].present?
        employees = employees.by_department(params[:department])                  if params[:department].present?
        employees = employees.where(employment_type: params[:employment_type])    if params[:employment_type].present?
        employees = employees.where("LOWER(full_name) LIKE ?", "%#{params[:search].downcase}%") if params[:search].present?

        employees = employees.order(:full_name).page(params[:page]).per(params[:per_page] || 25)

        render json: EmployeeSerializer.new(employees).serializable_hash.merge(
          meta: {
            current_page: employees.current_page,
            total_pages:  employees.total_pages,
            total_count:  employees.total_count
          }
        )
      end

      def show
        render json: EmployeeSerializer.new(@employee).serializable_hash
      end

      def create
        employee = Employee.new(employee_params)
        if employee.save
          render json: EmployeeSerializer.new(employee).serializable_hash,
                 status: :created
        else
          render json: { errors: employee.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def update
        if @employee.update(employee_params)
          render json: EmployeeSerializer.new(@employee).serializable_hash
        else
          render json: { errors: @employee.errors.full_messages },
                 status: :unprocessable_entity
        end
      end

      def destroy
        @employee.destroy
        head :no_content
      end

      private

      def set_employee
        @employee = Employee.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Employee not found" }, status: :not_found
      end

      def employee_params
        params.require(:employee).permit(
          :full_name, :job_title, :department, :country,
          :salary, :currency, :employment_type, :email, :hired_on
        )
      end
    end
  end
end
