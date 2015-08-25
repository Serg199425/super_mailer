class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts

  def index
  end

  def check_providers_account
    redirect_to action: 'providers#create' if current_user.provider_accounts.nil?
  end
end
