class CreateSettings < ActiveRecord::Migration[5.1]
  def change
    create_table :settings do |t|

      t.string :type_name
      t.string :validation
      t.string :default_value
      t.string :description

      t.timestamps
    end
  end
end
