class ProviderAccount < ActiveRecord::Base
  require 'bcrypt'
  extend Enumerize

  belongs_to :user
  has_many :letters, :dependent => :destroy

  validates :login, :password, :name, :address, :protocol, :port, presence: true

  enumerize :protocol, in: [:pop3, :imap, :smtp], scope: true
  enumerize :status, in: [:updating, :ready], scope: true

  after_save :copying_letters
  before_save :encrypt_password

  def copying_letters
    LettersUpdateWorker.perform_async(self.id, 'get_all') if self.copy_old_letters && self.copy_old_letters_changed?
  end

  def ready?
    self.status == :ready
  end

  def last_date
    last_letter = self.letters.with_group(:inbox, :trash).order('date asc').last
    last_date = last_letter ? last_letter.date : !self.copy_old_letters ? self.created_at : nil
  end

  def encrypt_password
    self.password = Base64.encode64(self.password) if self.password_changed?
  end

  def decrypt_password
    Base64.decode64(self.password)
  end
end
