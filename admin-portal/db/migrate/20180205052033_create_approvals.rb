class CreateApprovals < ActiveRecord::Migration[5.1]
  def change
    create_table :approvals do |t|
      t.string :table
      t.integer :row_id
      t.string :content
      t.timestamps
    end
  end
end
