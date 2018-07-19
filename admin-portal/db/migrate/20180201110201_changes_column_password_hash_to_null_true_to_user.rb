class ChangesColumnPasswordHashToNullTrueToUser < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :password_hash, :string, null: true
  end
end
