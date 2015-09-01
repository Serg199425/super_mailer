class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts

  def inbox
    @letters = Letter.where(group: :inbox).order('date desc').paginate(page: params[:page], per_page: LETTERS_PER_PAGE)
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
    update_letters
    redirect_to action: :inbox
  end

  private

  def check_providers_accounts
    redirect_to action: 'create', controller: 'providers' if current_user.provider_accounts.empty?
  end

  
  def update_letters
    current_user.provider_accounts.each do |provider_account|
      Mail.defaults do
        retriever_method  provider_account.protocol.to_sym, 
                          :address    => provider_account.address,
                          :port       => provider_account.port,
                          :user_name  => provider_account.login,
                          :password   => provider_account.password,
                          :enable_ssl => provider_account.enable_ssl
      end

      multiplier = 1
      loop do
        @mails = Mail.find(:what => :last, :count => LETTERS_FOR_UPDATE_QUERY * multiplier, :order => :asc)

        last_letter = Letter.where(group: :inbox).order('date asc').where(provider_account: provider_account).last

        @mails.reject! {|mail| mail.date <= last_letter.date } if last_letter
        break if @mails.count != LETTERS_FOR_UPDATE_QUERY * multiplier || LETTERS_FOR_UPDATE_LIMIT <= LETTERS_FOR_UPDATE_QUERY * multiplier
        multiplier += 1
      end

      @values = []
      @mails.each do |mail|
        @values << [ mail.subject, mail.parts.to_a, mail.date, mail.to, mail.from.first, current_user.id, provider_account.id, mail.body.decoded ]
      end

      columns = [:subject, :parts, :date, :to, :from, :user_id, :provider_account_id, :body]
      Letter.import columns, @values, :validate => false
    end
  end

  def provider_account_params
    params.require(:letter)
      .permit(:subject, :provider_account_id, :body) if params[:letter]
  end
end
