class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  layout :layout_by_resource
  before_action :set_locale

  protected

  def layout_by_resource
    if devise_controller?
      "devise_layout"
    else
      "application"
    end
  end

  def set_locale
    I18n.locale = current_user.try(:locale) || I18n.default_locale
    @locales = [ t('locales.en'), t('locales.rus') ]
  end
end
