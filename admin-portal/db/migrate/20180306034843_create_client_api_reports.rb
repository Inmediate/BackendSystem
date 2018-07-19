class CreateClientApiReports < ActiveRecord::Migration[5.1]
  def change
    create_table :client_api_reports do |t|
      t.integer :client_id
      t.string :client_api_key
      t.integer :client_api_id
      t.string :request_ip
      t.string :request_endpoint
      t.string :request_method
      t.string :request_format
      t.string :request_payload_format
      t.text :request_payload
      t.string :response_code
      t.text :response_payload
      t.timestamps
    end
  end
end
