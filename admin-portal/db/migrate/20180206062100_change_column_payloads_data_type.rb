class ChangeColumnPayloadsDataType < ActiveRecord::Migration[5.1]
  def change
    change_column :client_apis, :payloads, :text
  end
end
