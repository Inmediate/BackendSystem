class AddColumnInvitationAndResetPasswordSentAtToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :reset_password_send_at, :datetime
    add_column :users, :invitation_send_at, :datetime
  end
end
