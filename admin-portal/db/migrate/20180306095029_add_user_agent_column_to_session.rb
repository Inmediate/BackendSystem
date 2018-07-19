class AddUserAgentColumnToSession < ActiveRecord::Migration[5.1]
  def change
    add_column :sessions, :user_agent, :string
  end
end
