class ChangeColumnCacheTimeoutDefaultToInsurerProductApi < ActiveRecord::Migration[5.1]
  def change
    remove_column :insurer_product_apis, :cache_timeout
    add_column :insurer_product_apis, :cache_timeout, :integer, default: 24
  end
end
