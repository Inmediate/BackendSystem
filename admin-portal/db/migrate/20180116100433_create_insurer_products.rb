class CreateInsurerProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :insurer_products do |t|

      t.belongs_to :insurer
      t.belongs_to :product

      t.timestamps
    end
  end
end
