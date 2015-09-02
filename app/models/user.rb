class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :provider_accounts
  has_many :letters

  after_create :create_attachments_folder

  def create_attachments_folder
    FileUtils.mkdir("#{Rails.root}/public/attachments/user_#{self.id}/")
  end

  def letters_updating?
    self.provider_accounts.where(status: :updating).present?
  end
end
