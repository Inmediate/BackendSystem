class AddColoumApproveCreate < ActiveRecord::Migration[5.1]
  def change
    add_column :client_apis, :approve_create, :boolean, default: false
    add_column :clients, :approve_create, :boolean, default: false
    add_column :insurers, :approve_create, :boolean, default: false
  end
end
