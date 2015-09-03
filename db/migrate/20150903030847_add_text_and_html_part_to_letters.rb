class AddTextAndHtmlPartToLetters < ActiveRecord::Migration
  def self.up
    add_column :letters, :html_part, :text
    add_column :letters, :text_part, :text
    remove_column :letters, :parts
  end

  def self.down
    add_column :letters, :parts, array: true, default: []
    remove :letters, :html_part
    remove :letters, :text_part
  end
end
