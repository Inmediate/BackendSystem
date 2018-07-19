class ChangesPasswordHashNullTrueToUser < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :password_hash, :string
    add_column :users, :accept_invitation, :boolean, default: false
  end
end
