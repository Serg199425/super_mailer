class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts

  def index
    @letters = current_user.letters
  end

  def check_providers_accounts
    redirect_to action: 'create', controller: 'providers' if current_user.provider_accounts.empty?
  end
end
