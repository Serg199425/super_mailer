class Letter < ActiveRecord::Base
  extend Enumerize
  belongs_to :user
  belongs_to :provider_account
  has_many :attachments, :dependent => :destroy

  validates_associated :attachments
  accepts_nested_attributes_for :attachments

  validates :body, :to, :subject, :provider_account, :date, :user, :from, :group, presence: true

  enumerize :group, in: [:inbox, :outbox, :draft, :trash], scope: true

  before_validation :fill_columns, on: [:create, :update]

  def deliver
    return unless self.valid?
    provider_account = self.provider_account
    Mail.defaults do
      delivery_method :smtp, address: provider_account.address, port: 465, tls: true,
                      user_name: provider_account.login, password: provider_account.password 
    end

    mail = Mail.new(from: self.from, to: self.to, subject: self.subject )

    self.message_id = mail.message_id

    mail.html_part = Mail::Part.new(content_type: 'text/html; charset=UTF-8', body: self.body)

    self.attachments.each { |attachment| mail.add_file attachment.file.path }

    if mail.deliver!
      self.group = :outbox
      self.date = mail.date
    end
  end

  def fill_columns
    self.user = self.provider_account.user if self.provider_account
    self.from = self.provider_account.login if self.provider_account
    self.group = :draft
    self.date = Time.now
  end
end
