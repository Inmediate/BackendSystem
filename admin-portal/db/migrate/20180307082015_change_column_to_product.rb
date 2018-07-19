class ChangeColumnToProduct < ActiveRecord::Migration[5.1]
  def change
    remove_column :products, :approve_create
    add_column :products, :status, :boolean, default: true
  end
end
