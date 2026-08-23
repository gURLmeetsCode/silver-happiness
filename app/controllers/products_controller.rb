class ProductsController < ApplicationController
  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to safe_return_to(default: root_path), notice: "#{@product.name} saved to your products."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def lookup_barcode
    barcode = params[:barcode].to_s
    data = OpenFoodFacts.lookup(barcode)
    render json: data
  rescue OpenFoodFacts::NotFound => e
    render json: { error: e.message }, status: :not_found
  end

  def search
    results = OpenFoodFacts.search(params[:q].to_s)
    render json: { products: results }
  rescue OpenFoodFacts::NotFound => e
    render json: { error: e.message, products: [] }, status: :not_found
  end

  private

  def product_params
    params.require(:product).permit(
      :name, :brand, :barcode, :calories_per_100g, :protein_per_100g, :carbs_per_100g,
      :fat_per_100g, :default_serving_g, :serving_label, :notes,
      :beverage, :water_volume_ml
    )
  end
end
