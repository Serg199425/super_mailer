class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts
  before_action :set_letters_urls
  before_action :check_recieve_providers_accounts, only: [:inbox, :draft, :trash]
  before_action :check_send_providers_accounts, only: [:outbox, :edit, :deliver]

  def inbox
    @letters = letters_with_group [:inbox, :both]
    respond_to do |format|
      format.html
      format.js
    end
  end

  def outbox
    if current_user.send_providers_empty?
      redirect_to controller: :providers, action: :create
      return
    end
    @letters = letters_with_group [:outbox, :both]
  end

  def draft
    if current_user.recieve_providers_empty?
      redirect_to controller: :providers, action: :create
      return
    end
    @letters = letters_with_group :draft
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
      redirect_to action: :outbox if @letter.save && @letter.deliver
    end
  end

  def edit
    @letter = current_user.letters.with_group(:draft).find(params[:id])
    if request.post?
      @letter.to = params[:letter][:to].split(',')
      @letter.update(letter_params)
    end
  end

  def deliver
    @letter = current_user.letters.with_group(:draft).find(params[:id])
    redirect_to action: @letter.deliver ? :draft : :edit
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

  def check_recieve_providers_accounts
    if current_user.recieve_providers_empty?
      redirect_to controller: :providers, action: :create
      return
    end
  end

  def check_send_providers_accounts
    if current_user.send_providers_empty?
      redirect_to controller: :providers, action: :create
      return
    end
  end

  def update_letters(provider_account)
    if provider_account.status == :ready
      provider_account.update(status: :updating)
      LettersUpdateWorker.perform_async(provider_account.id)
    end
  end

  def letter_params
    params.require(:letter)
      .permit(:subject, :provider_account_id, :body, attachments_attributes: [:id, :file]) if params[:letter]
  end

  def letters_with_group(groups)
    current_user.letters.where(group: groups).order('date desc').paginate(page: params[:page], per_page: LETTERS_PER_PAGE)
  end
end
