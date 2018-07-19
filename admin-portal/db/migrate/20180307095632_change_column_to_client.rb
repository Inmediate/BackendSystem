class ChangeColumnToClient < ActiveRecord::Migration[5.1]
  def change
    remove_column :clients, :approve_create
    add_column :clients, :status, :boolean, default: true
  end
end
