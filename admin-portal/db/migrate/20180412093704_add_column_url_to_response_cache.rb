class AddColumnUrlToResponseCache < ActiveRecord::Migration[5.1]
  def change
    add_column :response_caches, :url, :text
  end
end
