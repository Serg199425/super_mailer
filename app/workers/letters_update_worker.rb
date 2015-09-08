class LettersUpdateWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false, :backtrace => false
  require 'net/pop'

  def perform(provider_account_id, operation = 'update')

    @provider_account = ProviderAccount.find(provider_account_id)
    return if @provider_account.nil? || @provider_account.ready?

    puts operation.to_s + " for user #{@provider_account.user.id}"

    options = { :address    => @provider_account.address, :port => @provider_account.port,
                :user_name  => @provider_account.login, :password   => @provider_account.decrypt_password,
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

    @attachments = []
    letters = @mails.map do |mail|
      Letter.new(subject: mail.subject, date: mail.date, to: mail.to, from: mail.from.first, 
        user_id: @provider_account.user_id, provider_account_id: @provider_account.id, text_part: text_part(mail), 
        html_part: html_part(mail), message_id: mail.message_id, group: get_group(mail))
    end

    Letter.import letters, :validate => false

    letters.each_with_index do |letter, index|
      @attachments.concat save_attachments(@mails[index], letter.id) if @mails[index].attachments.present?
    end

    Attachment.import @attachments, :validate => false

    @provider_account.update(status: :ready)

    WebsocketRails.users[@provider_account.user_id].send_message('updated', { letters_count: letters.count }, :namespace => 'letters')

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
    last_date = @provider_account.last_date
    (LETTERS_FOR_UPDATE_QUERY..LETTERS_FOR_UPDATE_LIMIT).step(LETTERS_FOR_UPDATE_QUERY) do |letters_count|
      @mails = Mail.find(:what => :first, :count => letters_count, :order => :asc)
      @mails.reject! {|mail| mail.date <= last_date } if last_date
      break if letters_count != @mails.count
    end
  end

  def get_all_mails
    @mails = Mail.all
    @provider_account.letters.destroy_all
  end

  def save_attachments(mail, letter_id)
    dir = create_folder(mail, letter_id)
    mail.attachments.map do |attachment|
      new_attachment = Attachment.new letter_id: letter_id
      File.open(dir + attachment.filename , 'wb') do |file| 
        file << attachment.decoded
        new_attachment.file = file
      end
      new_attachment
    end
  end

  def text_part(mail)
    mail.text_part.decoded if mail.multipart? && mail.text_part
  end

  def html_part(mail)
    mail.multipart? ? (mail.html_part.decoded if mail.html_part) : mail.body.decoded
  end

  def create_folder(mail, letter_id)
    user_id = @provider_account.user_id
    dir = File.dirname("#{Rails.root}/public/attachments/user_#{user_id}/file")
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    dir = "#{Rails.root}/public/attachments/user_#{user_id}/letter_id_#{letter_id}/"
    FileUtils.mkdir(dir) unless File.directory?(dir)
    dir
  end

  def get_group(mail)
    is_both?(mail) ? :both : ( is_outbox?(mail) ? :outbox : :inbox)
  end

  def is_outbox?(mail)
    mail.from.include? @provider_account.login
  end

  def is_inbox?(mail)
    mail.to.include? @provider_account.login
  end

  def is_both?(mail)
    is_inbox?(mail) && is_outbox?(mail)
  end
end