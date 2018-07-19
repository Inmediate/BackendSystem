class AddColumnActivationStatusToClient < ActiveRecord::Migration[5.1]
  def change
    change_column :clients, :activation_status, :boolean, default: false
  end
end
