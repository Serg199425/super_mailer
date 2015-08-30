class CreateLetters < ActiveRecord::Migration
  def change
    create_table :letters do |t|
      t.string :title
      t.string :body
      t.datetime :sended_at
      t.text :recipients, array: true, default: []
      t.timestamps null: false

      t.belongs_to :user
      t.belongs_to :provider_account
    end
  end
end
