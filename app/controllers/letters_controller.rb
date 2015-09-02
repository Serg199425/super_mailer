class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts
  before_action :set_letters_urls

  def inbox
    @letters = letters_with_group :inbox
    respond_to do |format|
      format.html
      format.js
    end
  end

  def outbox
    @letters = letters_with_group :outbox
  end

  def trash
    @letters = letters_with_group :trash
  end

  def show
    @letter = current_user.letters.find(params[:id])
  end

  def to_trash
    current_user.letters.find(params[:id]).update(group: :trash)
    redirect_to :back
  end

  def destroy
    current_user.letters.find(params[:id]).destroy
    redirect_to :back
  end

  def create
    @letter = Letter.new letter_params
    if request.post?
      @letter.to = params[:letter][:to].split(',')
      if @letter.save
        @letter.deliver
        redirect_to action: :outbox
      end
    end
  end

  def refresh
    respond_to do |format|
      format.js {
        current_user.provider_accounts.with_protocol(:imap, :pop3).each { |provider_account| update_letters(provider_account) } 
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

  def letter_params
    params.require(:letter)
      .permit(:subject, :provider_account_id, :body) if params[:letter]
  end

  def letters_with_group(group)
    current_user.letters.with_group(group).order('date desc').paginate(page: params[:page], per_page: LETTERS_PER_PAGE)
  end
end
