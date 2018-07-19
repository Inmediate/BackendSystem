class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|

      t.string :name, length: 100
      t.string :email, length: 100, null: false, index: true
      t.string :password
      t.boolean :activation_status, default: false
      t.string :reset_password_token
      t.string :invitation_token
      t.belongs_to :role

      t.timestamps
    end
  end
end
