class ChangeColumnToMapping < ActiveRecord::Migration[5.1]
  def change
    remove_column :mappings, :approve_create
    add_column :mappings, :status, :boolean, default: true
  end
end
