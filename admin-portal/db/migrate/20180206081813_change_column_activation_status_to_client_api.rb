class ChangeColumnActivationStatusToClientApi < ActiveRecord::Migration[5.1]
  def change
    remove_column :client_apis, :activation_status
    add_column :client_apis, :activation_status, :boolean, default: true
  end
end
