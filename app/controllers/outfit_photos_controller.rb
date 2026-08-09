class OutfitPhotosController < ApplicationController
  def index
    @category = params[:category]
    @outfit_photos = OutfitPhoto.recent.by_category(@category)
  end

  def new
    @outfit_photo = OutfitPhoto.new(
      logged_on: params[:logged_on].presence || Date.current,
      category: params[:category] || :feeling_cute
    )
  end

  def create
    @outfit_photo = OutfitPhoto.new(outfit_photo_params)

    if @outfit_photo.save
      redirect_to outfit_photos_path(category: @outfit_photo.category), notice: "Outfit photo saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @outfit_photo = OutfitPhoto.find(params[:id])
    @outfit_photo.destroy
    redirect_to outfit_photos_path, notice: "Photo removed."
  end

  private

  def outfit_photo_params
    attrs = params.require(:outfit_photo).permit(:logged_on, :category, :caption, :note, :image)
    attrs[:image] = ImageDownscaler.call(attrs[:image]) if attrs[:image].present?
    attrs
  end
end
