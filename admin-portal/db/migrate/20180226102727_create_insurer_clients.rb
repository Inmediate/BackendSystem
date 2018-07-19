class CreateInsurerClients < ActiveRecord::Migration[5.1]
  def change
    create_table :insurer_clients do |t|

      t.belongs_to :insurer
      t.belongs_to :client

      t.timestamps
    end
  end
end
