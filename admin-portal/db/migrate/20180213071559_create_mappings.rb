class CreateMappings < ActiveRecord::Migration[5.1]
  def change
    create_table :mappings do |t|
      t.string :name
      t.text :list
      t.boolean :approve_create, default: false
      t.timestamps
    end
  end
end
