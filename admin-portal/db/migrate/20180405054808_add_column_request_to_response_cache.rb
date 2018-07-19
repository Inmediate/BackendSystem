class AddColumnRequestToResponseCache < ActiveRecord::Migration[5.1]
  def change
    remove_column :response_caches, :payload
    add_column :response_caches, :request, :text
  end
end
