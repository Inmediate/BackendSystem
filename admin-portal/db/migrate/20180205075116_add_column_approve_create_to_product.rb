class AddColumnApproveCreateToProduct < ActiveRecord::Migration[5.1]
  def change
    add_column :products, :approve_create, :boolean, default: false
  end
end
