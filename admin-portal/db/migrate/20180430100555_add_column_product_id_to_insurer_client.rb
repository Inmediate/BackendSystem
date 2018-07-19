class AddColumnProductIdToInsurerClient < ActiveRecord::Migration[5.1]
  def change
    add_column :insurer_clients, :product_id, :integer
  end
end
