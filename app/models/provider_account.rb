class ProviderAccount < ActiveRecord::Base
  require 'bcrypt'
  extend Enumerize

  belongs_to :user
  has_many :letters

  validates :login, :password, :name, :address, :protocol, :port, presence: true

  enumerize :protocol, in: [:pop3, :imap]
end
