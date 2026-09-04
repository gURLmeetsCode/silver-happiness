class ProductsController < ApplicationController
  def new
    @product = Product.new
  end

  def create
    attrs = product_params.to_h
    existing = find_existing_product(attrs)
    @product = existing || Product.new
    @product.assign_attributes(attrs)

    if @product.save
      notice = if existing
        "#{@product.name} was already in your products — updated instead of duplicating."
      else
        "#{@product.name} saved to your products."
      end
      redirect_to safe_return_to(default: root_path), notice: notice
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

  def find_existing_product(attrs)
    barcode = attrs[:barcode].to_s.strip.presence || attrs["barcode"].to_s.strip.presence
    name = attrs[:name].to_s.strip.presence || attrs["name"].to_s.strip.presence
    if barcode.present?
      Product.find_by(barcode: barcode) || (name.present? && Product.find_by("LOWER(name) = ?", name.downcase)) || nil
    elsif name.present?
      Product.find_by("LOWER(name) = ?", name.downcase)
    end
  end

  def product_params
    params.require(:product).permit(
      :name, :brand, :barcode, :calories_per_100g, :protein_per_100g, :carbs_per_100g,
      :fat_per_100g, :default_serving_g, :serving_label, :notes,
      :beverage, :water_volume_ml
    )
  end
end
