module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :set_employee, only: [:show, :update, :destroy]

      def index
        employees = Employee.filter(filter_params)
                            .sorted(params[:sort], params[:direction])
                            .page(params[:page])
                            .per(params[:per_page] || 25)

        render json: EmployeeSerializer.new(employees).serializable_hash
                                       .merge(meta: pagination_meta(employees))
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

      def filter_params
        params.permit(:country, :job_title, :department, :employment_type, :search)
      end

      def employee_params
        params.require(:employee).permit(
          :full_name, :job_title, :department, :country,
          :salary, :currency, :employment_type, :email, :hired_on
        )
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages:  collection.total_pages,
          total_count:  collection.total_count
        }
      end
    end
  end
end

