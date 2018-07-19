class AddVersionColumnToSession < ActiveRecord::Migration[5.1]
  def change
    remove_column :sessions, :user_agent
    add_column :sessions, :version, :string
  end
end
