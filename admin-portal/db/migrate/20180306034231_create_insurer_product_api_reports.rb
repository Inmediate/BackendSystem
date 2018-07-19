class CreateInsurerProductApiReports < ActiveRecord::Migration[5.1]
  def change
    create_table :insurer_product_api_reports do |t|
      t.integer :insurer_product_api_id
      t.integer :request_id
      t.string :source
      t.string :request_url
      t.string :request_method
      t.text :request_payload
      t.string :response_code
      t.text :response_payload
      t.timestamps
    end
  end
end
