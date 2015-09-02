class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts
  before_action :set_letters_urls

  def inbox
    @letters = Letter.where(group: :inbox).order('date desc').paginate(page: params[:page], per_page: LETTERS_PER_PAGE)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def outbox
    @letters = Letter.where(group: :outbox).order('date desc').paginate(page: params[:page], per_page: LETTERS_PER_PAGE)
  end

  def show
    @letter = Letter.find(params[:id])
  end

  def create
    @letter = Letter.new provider_account_params
    if request.post?
      @letter.user = current_user
      @letter.from = current_user.email
      @letter.to = params[:letter][:to].split(',')
      @letter.group = :draft
      @letter.date = Time.now
      @letter.deliver if @letter.save
    end
  end

  def refresh
    respond_to do |format|
      format.js {
        current_user.provider_accounts.each { |provider_account| update_letters(provider_account) } 
      }
    end
  end

  private

  def set_letters_urls
    gon.letters_inbox_path = letters_inbox_path
    gon.letters_refresh_path = letters_refresh_path
  end
  def check_providers_accounts
    redirect_to action: 'create', controller: 'providers' if current_user.provider_accounts.blank?
  end

  
  def update_letters(provider_account)
    if provider_account.status == :ready
      provider_account.update(status: :updating)
      LettersUpdateWorker.perform_async(provider_account.id)
    end
  end

  def provider_account_params
    params.require(:letter)
      .permit(:subject, :provider_account_id, :body) if params[:letter]
  end
end
