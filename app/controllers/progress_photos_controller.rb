class ProgressPhotosController < ApplicationController
  before_action :set_daily_log

  def create
    @photo = @daily_log.progress_photos.build(progress_photo_params)

    if @photo.save
      redirect_to photos_tab, notice: "Progress photo uploaded."
    else
      redirect_to photos_tab, alert: @photo.errors.full_messages.to_sentence
    end
  end

  def destroy
    @photo = @daily_log.progress_photos.find(params[:id])
    @photo.destroy
    redirect_to photos_tab, notice: "Photo removed."
  end

  private

  # The day log opens on Food & drink, so without the anchor the photo you just
  # uploaded is sitting on a tab you cannot see.
  def photos_tab
    daily_log_path(@daily_log, anchor: "photos")
  end

  def set_daily_log
    @daily_log = DailyLog.find(params[:daily_log_id])
  end

  def progress_photo_params
    attrs = params.require(:progress_photo).permit(:photo_type, :caption, :image)
    attrs[:image] = ImageDownscaler.call(attrs[:image]) if attrs[:image].present?
    attrs
  end
end
