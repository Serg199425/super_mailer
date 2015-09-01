class LettersUpdateWorker
  include Sidekiq::Worker

  def perform(user_id, provider_account_id)
    user = User.find(user_id)
    provider_account = user.provider_accounts.find_by(id: provider_account_id)
    return unless provider_account

    Mail.defaults do
      retriever_method  provider_account.protocol.to_sym, 
                        :address    => provider_account.address,
                        :port       => provider_account.port,
                        :user_name  => provider_account.login,
                        :password   => provider_account.password,
                        :enable_ssl => provider_account.enable_ssl
    end

    mails = Mail.last
    last_letter = provider_account.letters.order('date asc').last
    mails.reject! {|mail| mail.date <= last_letter.date } if last_letter

    letters = mails.map do |mail|
      new_letter = Letter.new(subject: mail.subject, parts: mail.parts.to_a, date: mail.date, to: mail.to, 
        from: mail.from.first, user: user, provider_account: provider_account, body: mail.body.decoded, 
        message_id: mail.message_id, attachments: attachments(mail, user.id))
    end

    Letter.import letters

    rescue Net::POPAuthenticationError => e
      puts 'Update Error: #{e.message}'
  end

  private

  def attachments(mail, user_id)
      dir = FileUtils.mkdir("#{Rails.root}/public/attachments/user_#{user_id}/message_id_#{mail.message_id}/") 
      mail.attachments.map do |attachment| 
        File.open(dir[0] + attachment.filename , 'wb') { |file| file << attachment.decoded }
        attachment.filename
      end
  end 
end