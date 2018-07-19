class AddColumnToResponseCache < ActiveRecord::Migration[5.1]
  def change
    add_column :response_caches, :payload, :text
  end
end
