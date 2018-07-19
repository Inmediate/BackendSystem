class ChangeColumnToClientApi < ActiveRecord::Migration[5.1]
  def change
    add_column :client_apis, :status, :boolean, default: true
  end
end
