class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|

      t.string :name, null: false
      t.string :code, null: false, index: true
      t.boolean :activation_status, default: false

      t.timestamps
    end
  end
end
