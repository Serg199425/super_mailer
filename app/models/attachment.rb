class Attachment < ActiveRecord::Base
  belongs_to :letter

  has_attached_file :file, :url => "/attachments/user_:user_id/letter_id_:letter_id/:basename.:extension",
                    :path => "#{Rails.root}/public/attachments/user_:user_id/letter_id_:letter_id/:basename.:extension"
  do_not_validate_attachment_file_type :file

  Paperclip.interpolates :user_id do |attachment, style|
    attachment.instance.letter.user_id
  end

  Paperclip.interpolates :letter_id do |attachment, style|
    attachment.instance.letter_id
  end
end
