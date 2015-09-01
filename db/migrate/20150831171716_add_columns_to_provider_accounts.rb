class AddColumnsToProviderAccounts < ActiveRecord::Migration
  def change
    add_column :provider_accounts, :copy_old_letters, :boolean, default: true
  end
end
