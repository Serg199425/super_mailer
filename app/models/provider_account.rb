class ProviderAccount < ActiveRecord::Base
  require 'bcrypt'
  extend Enumerize

  belongs_to :user
  has_many :letters

  validates :login, :password, :name, :address, :protocol, :port, presence: true

  enumerize :protocol, in: [:pop3, :imap]

  after_save :copying_letters

  def copying_letters
    LettersUpdateWorker.perform_async(self.id, 'get_all') if self.copy_old_letters && self.copy_old_letters_changed?
  end
end
