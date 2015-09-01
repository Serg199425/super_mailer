class LettersUpdateWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false
  require 'net/pop'

  def perform(provider_account_id, operation = 'update')
    @provider_account = ProviderAccount.find(provider_account_id)
    return if @provider_account.nil?

    puts operation.to_s + " for user #{@provider_account.user.id}"

    options = { :address    => @provider_account.address, :port => @provider_account.port,
                :user_name  => @provider_account.login, :password   => @provider_account.password,
                :enable_ssl => @provider_account.enable_ssl
              }

    protocol = @provider_account.protocol.to_sym

    Mail.defaults { retriever_method  protocol, options }

    get_mails(operation)
    return if @mails.blank?

    letters = @mails.map do |mail|
      new_letter = Letter.new(subject: mail.subject, parts: mail.parts.to_a, date: mail.date, to: mail.to, 
        from: mail.from.first, user: @provider_account.user, provider_account: @provider_account, body: mail.body.decoded, 
        message_id: mail.message_id, attachments: [])
    end

    Letter.import letters

    rescue Net::POPAuthenticationError, ActiveRecord::RecordNotFound => e
      puts "#{operation.to_s} error: #{e.message}"
  end

  private

  def get_mails(operation)
    operation == 'update' ? update_mails : (get_all_mails if operation == 'get_all')
  end

  def update_mails
    last_letter = @provider_account.letters.where(group: :inbox).order('date asc').last
    last_date = last_letter ? last_letter.date : !@provider_account.copy_old_letters ? @provider_account.created_at : nil
    (LETTERS_FOR_UPDATE_QUERY..LETTERS_FOR_UPDATE_LIMIT).step(LETTERS_FOR_UPDATE_QUERY) do |letters_count|
      @mails = Mail.find(:what => :last, :count => letters_count, :order => :asc)
      @mails.reject! {|mail| mail.date <= last_date } if last_date
      break if letters_count != @mails
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
end