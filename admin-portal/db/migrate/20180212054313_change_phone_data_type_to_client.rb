class ChangePhoneDataTypeToClient < ActiveRecord::Migration[5.1]
  def change
    remove_column :clients, :phone
    remove_column :clients, :contact_person_phone
    add_column :clients, :phone, :string
    add_column :clients, :contact_person_phone, :string
  end
end
