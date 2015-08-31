class LettersController < ApplicationController
  before_action :authenticate_user!
  before_action :check_providers_accounts

  def index
    update_letters
    @letters = Letter.all.paginate(page: params[:page], per_page: LETTERS_PER_PAGE)
  end


  def show
    @letter = Letter.find(params[:id])
  end

  private

  def check_providers_accounts
    redirect_to action: 'create', controller: 'providers' if current_user.provider_accounts.empty?
  end

  
  def update_letters
    current_user.provider_accounts.each do |provider_account|
      Mail.defaults do
        retriever_method :pop3, :address    => provider_account.address,
                                :port       => provider_account.port,
                                :user_name  => provider_account.login,
                                :password   => provider_account.password,
                                :enable_ssl => provider_account.enable_ssl
      end

      multiplier = 1
      loop do
        @mails = Mail.find(:what => :last, :count => LETTERS_FOR_UPDATE_QUERY * multiplier, :order => :asc)

        last_letter = Letter.order('date asc').where(provider_account: provider_account).last

        @mails.reject! {|mail| mail.date <= last_letter.date } if last_letter
        break if @mails.count != LETTERS_FOR_UPDATE_QUERY * multiplier || LETTERS_FOR_UPDATE_LIMIT <= LETTERS_FOR_UPDATE_QUERY * multiplier
        multiplier += 1
      end

      @values = []
      @mails.each do |mail|
        @values << [ mail.subject, mail.parts.to_a, mail.date, mail.to, mail.from, current_user.id, provider_account.id, mail.body.decoded ]
      end

      columns = [:subject, :parts, :date, :to, :from, :user_id, :provider_account_id, :body]
      Letter.import columns, @values, :validate => false
    end
  end
end
