class ProductsController < ApplicationController
  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to params[:return_to].presence || root_path, notice: "#{@product.name} saved to your products."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def product_params
    params.require(:product).permit(
      :name, :brand, :calories_per_100g, :protein_per_100g, :carbs_per_100g,
      :fat_per_100g, :default_serving_g, :serving_label, :notes
    )
  end
end
