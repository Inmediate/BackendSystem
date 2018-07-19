class CreateInsurerProductApis < ActiveRecord::Migration[5.1]
  def change
    create_table :insurer_product_apis do |t|

      t.boolean :is_authentication, default: false
      t.string :auth_token_key_name
      t.belongs_to :client_api
      t.belongs_to :insurer
      t.string :cache_policy
      t.integer :cache_timeout
      t.boolean :activation_status, default: false
      t.text :api_url
      t.string :api_method
      t.string :api_flavour
      t.text :auth_scheme_name
      t.text :credential
      t.string :auth_api
      t.string :payload_type
      t.text :payload
      t.text :RSA_encrypt_public_key
      t.boolean :validation, default: true
      t.text :payload_validation
      t.string :headers
      t.boolean :approve_create, default: false

      t.timestamps
    end
  end
end
