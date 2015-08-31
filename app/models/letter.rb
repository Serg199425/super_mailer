class Letter < ActiveRecord::Base
  belongs_to :user
  belongs_to :provider_account
end
