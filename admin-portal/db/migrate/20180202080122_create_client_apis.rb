class CreateClientApis < ActiveRecord::Migration[5.1]
  def change
    create_table :client_apis do |t|

      t.string :name
      t.belongs_to :product
      t.string :path
      t.string :method
      t.boolean :authorization, default: true
      t.boolean :authorization, default: true
      t.string :payloads
      t.string :activation_status
      t.string :derived_from
      t.string :description
      t.timestamps
    end
  end
end
