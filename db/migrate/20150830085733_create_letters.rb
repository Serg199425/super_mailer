class CreateLetters < ActiveRecord::Migration
  def change
    create_table :letters do |t|
      t.string :subject
      t.text :body
      t.text :parts, array: true, default: []
      t.datetime :date
      t.text :from, array: true, default: []
      t.text :to, array: true, default: []
      t.timestamps null: false

      t.belongs_to :user
      t.belongs_to :provider_account
    end
  end
end
