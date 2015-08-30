class CreateProviderAccounts < ActiveRecord::Migration
  def change
    create_table :provider_accounts do |t|
      t.string :name
      t.string :address
      t.string :protocol
      t.integer :port
      t.boolean :enable_ssl

      t.string :login
      t.string :password
      t.belongs_to :user
      
      t.timestamps null: false
    end
  end
end
