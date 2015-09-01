class CreateLetters < ActiveRecord::Migration
  def change
    create_table :letters do |t|
      t.string :subject
      t.text :body
      t.text :parts
      t.datetime :date
      t.string :from
      t.text :to, array: true, default: []
      t.string :group, default: :inbox
      t.string :message_id
      t.text :attachments, array: true, default: []
      t.timestamps null: false

      t.belongs_to :user
      t.belongs_to :provider_account
    end
  end
end
