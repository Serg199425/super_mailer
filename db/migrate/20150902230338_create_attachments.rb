class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments do |t|
      t.belongs_to :letter
    end
    add_attachment :attachments, :file
  end

  def self.down
    drop_rable :attachments
  end
end
