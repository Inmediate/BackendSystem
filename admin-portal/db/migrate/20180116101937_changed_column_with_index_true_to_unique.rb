class ChangedColumnWithIndexTrueToUnique < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :email, :string, unique: true
    change_column :clients, :client_code, :string, unique: true
    change_column :clients, :client_api_key, :string, unique: true
    change_column :products, :code, :string, unique: true
  end
end
