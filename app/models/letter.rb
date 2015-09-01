class Letter < ActiveRecord::Base
  extend Enumerize
  belongs_to :user
  belongs_to :provider_account

  validates :body, :to, :from, :subject, :user, :provider_account, :date, presence: true

  enumerize :group, in: [:inbox, :outbox, :draft]

  serialize :parts

  def deliver
    return unless self.valid?

    Mail.defaults do
      delivery_method :smtp, :address    => "smtp.yandex.ru",
                              :port       => 465,
                              :user_name  => 'serg199425@tut.by',
                              :password   => '19941994',
                              :enable_ssl => true
    end

    letter = self
    mail = Mail.new do
      from     letter.from
      to       letter.to
      subject  letter.subject
      body     letter.body
    end

    if mail.deliver
      self.group = :outbox
      return true
    else
      return false
    end
  end
end
