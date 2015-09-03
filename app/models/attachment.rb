class Attachment < ActiveRecord::Base
  belongs_to :letter

  has_attached_file :file, :path => ":rails_root/public/attachments/user_:user_id/message_id_:message_id/:basename.:extension"
  do_not_validate_attachment_file_type :file

  Paperclip.interpolates :user_id do |attachment, style|
    attachment.instance.letter.user.id
  end

  Paperclip.interpolates :message_id do |attachment, style|
    attachment.instance.letter.message_id ? attachment.instance.letter.message_id : attachment.instance.id
  end
end
