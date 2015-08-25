class CreateProviders < ActiveRecord::Migration
  def change
    create_table :providers do |t|
      t.string :name
      t.string :address
      t.string :protocol
      t.integer :port
      t.boolean :enable_ssl
      t.timestamps null: false
    end
  end
end
