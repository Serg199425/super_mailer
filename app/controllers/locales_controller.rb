class LocalesController < ApplicationController
  before_action :authenticate_user!
  def change
    current_user.update(locale: params[:locale])
    redirect_to :back
  end
end
