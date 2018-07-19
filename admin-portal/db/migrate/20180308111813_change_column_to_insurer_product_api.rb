class ChangeColumnToInsurerProductApi < ActiveRecord::Migration[5.1]
  def change
    remove_column :insurer_product_apis, :approve_create
    add_column :insurer_product_apis, :status, :boolean, default: true
  end
end
