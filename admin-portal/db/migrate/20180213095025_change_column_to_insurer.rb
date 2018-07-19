class ChangeColumnToInsurer < ActiveRecord::Migration[5.1]
  def change
    remove_column :insurers, :company_phone
    add_column :insurers, :company_phone, :string
    add_column :insurers, :mapping, :text
  end
end
