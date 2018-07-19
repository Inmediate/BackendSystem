class CreateResponseCaches < ActiveRecord::Migration[5.1]
  def change
    create_table :response_caches do |t|

      t.integer :insurer_product_api_id
      t.text :payload_sha256
      t.text :response
      t.datetime :expired_at
      t.timestamps
    end
  end
end
