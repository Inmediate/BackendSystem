class ChangeColumnToInsurerProductApiReport < ActiveRecord::Migration[5.1]
  def change
    remove_column :insurer_product_api_reports, :request_id
    add_column :insurer_product_api_reports, :request_id, :string
  end
end
