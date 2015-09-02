class AddStatusToProviderAccount < ActiveRecord::Migration
  def change
    add_column :provider_accounts, :status, :string, default: :ready
  end
end
