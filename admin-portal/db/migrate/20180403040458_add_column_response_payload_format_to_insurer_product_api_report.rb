class AddColumnResponsePayloadFormatToInsurerProductApiReport < ActiveRecord::Migration[5.1]
  def change
    add_column :insurer_product_api_reports, :response_format, :string
    add_column :insurer_product_api_reports, :request_format, :string
  end
end
