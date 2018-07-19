class CreateClientApiClients < ActiveRecord::Migration[5.1]
  def change
    create_table :client_api_clients do |t|

      t.belongs_to :client_api
      t.belongs_to :client

      t.timestamps
    end
  end
end
