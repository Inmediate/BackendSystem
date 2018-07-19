class ChangeColumnDataTypeaToApprovalContent < ActiveRecord::Migration[5.1]
  def change
    remove_column :approvals, :content
    add_column :approvals, :content, :text
  end
end
