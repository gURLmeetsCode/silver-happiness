class ProgressPhotosController < ApplicationController
  before_action :set_daily_log

  def create
    @photo = @daily_log.progress_photos.build(progress_photo_params)

    if @photo.save
      redirect_to @daily_log, notice: "Progress photo uploaded."
    else
      redirect_to @daily_log, alert: @photo.errors.full_messages.to_sentence
    end
  end

  def destroy
    @photo = @daily_log.progress_photos.find(params[:id])
    @photo.destroy
    redirect_to @daily_log, notice: "Photo removed."
  end

  private

  def set_daily_log
    @daily_log = DailyLog.find(params[:daily_log_id])
  end

  def progress_photo_params
    params.require(:progress_photo).permit(:photo_type, :caption, :image)
  end
end
