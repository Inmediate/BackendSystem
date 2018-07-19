class AddColumnStatusToInsurer < ActiveRecord::Migration[5.1]
  def change
    remove_column :insurers, :approve_create
    add_column :insurers, :status, :boolean, default: true
  end
end
