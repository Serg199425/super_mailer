class Provider < ActiveRecord::Base
  extend Enumerize

  enumerize :protocol, in: [:pop3, :imap]
end
