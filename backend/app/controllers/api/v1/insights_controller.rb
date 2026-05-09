module Api
  module V1
    class InsightsController < ApplicationController
      def index
        return render json: { error: "country param is required" },
                      status: :bad_request if params[:country].blank?

        render json: InsightsQuery.call(country: params[:country])
      end

      def countries
        render json: { countries: InsightsQuery.countries }
      end
    end
  end
end
