class PhotosController < ApplicationController
  before_action :authenticate_user!, on: [:create]
  before_action :set_event, only: %i[create destroy]
  before_action :set_photo, only: [:destroy]

  def create
    @new_photo = @event.photos.build(photo_params)
    @new_photo.user = current_user
    if @new_photo.save
      notify_subscribers(@event, @new_photo)
      redirect_to @event, notice: I18n.t('controllers.photos.created')
    else
      render 'events/show', alert: I18n.t('controllers.photos.error')
    end
  end

  def destroy
    message = { notice: I18n.t('controllers.photos.destroyed') }

    @photo.destroy

    redirect_to @event, message
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_photo
    @photo = @event.photos.find(params[:id])
  end

  def photo_params
    # params.fetch(:photo, {}).permit(:attached_photo)
    params.require(:photo).permit(:attached_photo)
  end

  def notify_subscribers(event, photo)
    # Собираем всех подписчиков и автора события в массив мэйлов, исключаем повторяющиеся
    all_emails = (event.subscriptions.map(&:user_email) + [event.user.email] - [photo.user&.email]).uniq

    # По адресам из этого массива делаем рассылку
    # Как и в подписках, берём EventMailer и его метод comment с параметрами
    # И отсылаем в том же потоке
    all_emails.each do |email|
      EventMailer.photo(photo, email).deliver_now
    end
  end
end
