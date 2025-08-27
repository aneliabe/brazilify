class CategoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    @categories = Category.includes(:services)
  end

    def services
    category = Category.find(params[:id])
    render json: category.services.select(:id, :name)
  end
end
