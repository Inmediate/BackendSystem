class CreateClients < ActiveRecord::Migration[5.1]
  def change
    create_table :clients do |t|

      t.string :name, null: false
      t.text :address
      t.integer :phone
      t.string :website_url
      t.string :contact_person_name
      t.integer :contact_person_phone
      t.string :contact_person_email
      t.string :broker_code
      t.string :billing_type
      t.string :whitelisted_ip
      t.integer :monthly_api_threshold
      t.string :client_code, index: true
      t.string :client_api_key, index: true
      t.string :activation_status

      t.timestamps
    end
  end
end
