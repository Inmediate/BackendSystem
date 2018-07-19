class AddColumnValidationToClientApi < ActiveRecord::Migration[5.1]
  def change
    add_column :client_apis, :validation, :boolean, default: true
  end
end
