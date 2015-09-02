class RemoveAttachmentsColumnFromLetters < ActiveRecord::Migration
  def self.up
    remove_column :letters, :attachments
  end

  def self.down
    add_column :letters, :attachments, :text, array: true, default: []
  end
end
