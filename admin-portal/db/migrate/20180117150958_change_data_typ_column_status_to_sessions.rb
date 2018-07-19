class ChangeDataTypColumnStatusToSessions < ActiveRecord::Migration[5.1]
  def change
    change_column :sessions, :status, :boolean, default: true
  end
end
