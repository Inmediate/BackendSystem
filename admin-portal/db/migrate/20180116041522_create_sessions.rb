class CreateSessions < ActiveRecord::Migration[5.1]
  def change
    create_table :sessions do |t|

      t.belongs_to :user
      t.string :status, default: true
      t.string :platform, null: false
      t.string :browser
      t.string :ip_address
      t.datetime :expired_at

      t.timestamps
    end
  end
end
