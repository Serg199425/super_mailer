class ProviderAccount < ActiveRecord::Base
  require 'bcrypt'

  belongs_to :provider
  belongs_to :user

  # before_save :hash_password

  # private
  # def hash_password
  #   self.password = BCrypt::Password.create(self.password) if self.password_changed?
  # end
end
