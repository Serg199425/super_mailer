class LettersUpdateWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :backtrace => false
  require 'net/pop'

  def perform(provider_account_id, operation = 'update')

    @provider_account = ProviderAccount.find(provider_account_id)
    return if @provider_account.nil? || @provider_account.ready?

    puts operation.to_s + " for user #{@provider_account.user.id}"

    options = { :address    => @provider_account.address, :port => @provider_account.port,
                :user_name  => @provider_account.login, :password   => @provider_account.password,
                :enable_ssl => @provider_account.enable_ssl
              }

    protocol = @provider_account.protocol.to_sym

    Mail.defaults { retriever_method  protocol, options }

    get_mails(operation)
    if @mails.blank?
      @provider_account.update(status: :ready)
      WebsocketRails.users[@provider_account.user.id].send_message('updated', { letters_count: 0 }, :namespace => 'letters')
      return
    end

    letters = @mails.map do |mail|
      [mail.subject, [], mail.date, mail.to, mail.from.first, @provider_account.user.id, 
        @provider_account.id, encode(mail.body.decoded), mail.message_id, attachments(mail)]
    end

    columns = [:subject, :parts, :date, :to, :from, :user_id, :provider_account_id, :body, :message_id, :attachments]

    Letter.import columns, letters

    @provider_account.update(status: :ready)

    WebsocketRails.users[@provider_account.user.id].send_message('updated', { letters_count: letters.count }, :namespace => 'letters')

    rescue => e
      message = "#{operation.to_s} error: #{e.message}"
      puts message
      @provider_account.update(status: :ready)
      WebsocketRails.users[@provider_account.user.id].send_message('updated', { error: true }, :namespace => 'letters')
  end

  def get_mails(operation)
    operation == 'update' ? update_mails : (get_all_mails if operation == 'get_all')
  end

  def update_mails
    (LETTERS_FOR_UPDATE_QUERY..LETTERS_FOR_UPDATE_LIMIT).step(LETTERS_FOR_UPDATE_QUERY) do |letters_count|
      @mails = Mail.find(:what => :last, :count => letters_count, :order => :asc)
      @mails.reject! {|mail| mail.date <= @provider_account.last_date } if @provider_account.last_date
      break if letters_count != @mails.count
    end
  end

  def get_all_mails
    @mails = Mail.all
    @provider_account.letters.destroy_all
  end


  def attachments(mail)
      return [] if mail.attachments.blank?
      user_id = @provider_account.user.id
      dir = FileUtils.mkdir("#{Rails.root}/public/attachments/user_#{user_id}/message_id_#{mail.message_id}/") 
      mail.attachments.map do |attachment| 
        File.open(dir[0] + attachment.filename , 'wb') { |file| file << attachment.decoded }
        attachment.filename
      end
  end

  def encode(string)
    string.force_encoding('iso8859-1').encode('utf-8')
  end
end