class Letter < ActiveRecord::Base
  extend Enumerize
  belongs_to :user
  belongs_to :provider_account

  validates :body, :to, :from, :subject, :provider_account, :date, presence: true

  enumerize :group, in: [:inbox, :outbox, :draft, :trash], scope: true

  before_validation :fill_columns, on: [:create, :update]

  def deliver
    return unless self.valid?
    provider_account = self.provider_account
    Mail.defaults do
      delivery_method :smtp, address: "smtp.yandex.ru", port: 465, tls: true,
                      user_name: provider_account.login, password: provider_account.password 
    end

    mail = Mail.new(from: self.from, to: self.to, subject: self.subject )

    mail.html_part = Mail::Part.new(content_type: 'text/html; charset=UTF-8', body: self.body)

    if mail.deliver!
      self.group = :outbox
      return true
    else
      return false
    end
  end

  def fill_columns
    self.from = self.provider_account.login if self.provider_account
    self.group = :draft
    self.date = Time.now
  end
end
