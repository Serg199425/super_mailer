class User < ActiveRecord::Base
  extend Enumerize

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :provider_accounts
  has_many :letters

  enumerize :locale, in: [:en, :rus], scope: true

  after_create :create_attachments_folder

  def create_attachments_folder
    FileUtils.mkdir("#{Rails.root}/public/attachments/user_#{self.id}/")
  end

  def letters_updating?
    self.provider_accounts.with_status(:updating).present?
  end

  def recieve_providers_empty?
    self.provider_accounts.with_protocol(:imap, :pop3).blank?
  end

  def send_providers_empty?
    self.provider_accounts.with_protocol(:smtp).blank?
  end
end
