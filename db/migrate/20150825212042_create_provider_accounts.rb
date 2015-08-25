class CreateProviderAccounts < ActiveRecord::Migration
  def change
    create_table :provider_accounts do |t|
      t.string :login
      t.string :password
      t.timestamps null: false
    end
  end
end
