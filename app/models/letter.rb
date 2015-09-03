class Letter < ActiveRecord::Base
  extend Enumerize
  belongs_to :user
  belongs_to :provider_account
  has_many :attachments, :dependent => :destroy

  accepts_nested_attributes_for :attachments

  validates :to, :subject, :provider_account, :date, :user, :from, :group, presence: true

  enumerize :group, in: [:inbox, :outbox, :draft, :trash], scope: true

  before_validation :fill_columns, on: [:create]
  before_destroy :delete_attachments

  def deliver
    return unless self.valid?
    provider_account = self.provider_account
    Mail.defaults do
      delivery_method :smtp, address: provider_account.address, port: 465, tls: true,
                      user_name: provider_account.login, password: provider_account.decrypt_password 
    end

    mail = Mail.new(from: self.from, to: self.to, subject: self.subject )

    self.message_id = mail.message_id

    mail.html_part = Mail::Part.new(content_type: 'text/html; charset=UTF-8', body: self.body)

    self.attachments.each { |attachment| mail.add_file attachment.file.path }

    mail.deliver!
    self.update(group: :outbox, date: mail.date)
    rescue => e
      self.errors[:base] << e.message
      return false
  end

  def fill_columns
    self.user = self.provider_account.user if self.provider_account
    self.from = self.provider_account.login if self.provider_account
    self.group = :draft
    self.date = Time.now
  end

  def delete_attachments
    return if self.attachments.blank?
    FileUtils.rm_rf(Dir.glob("#{Rails.root}/public/attachments/user_#{self.user_id}/message_id_#{self.message_id}/")) if self.message_id
  end
end
