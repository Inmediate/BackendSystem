require "rails_helper"

RSpec.describe ApprovalPendingMailer, type: :mailer do

  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
  end

  after(:each) do
    ActionMailer::Base.deliveries.clear
  end

  describe 'Send Reminder' do

    it 'if there is no pending approvals' do
      ApprovalPendingMailer.reminder(nil, '').deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it 'if there is no pending admins available' do
      approval = create(:approval)
      ApprovalPendingMailer.reminder(approval, nil).deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(0)
    end

    it 'should send an email' do
      approval = create(:approval)
      approval_array = Approval.where(id: approval.id)
      role = create(:role, id: 2)
      admin = create(:user, role_id: role.id)
      ApprovalPendingMailer.reminder(approval_array, admin).deliver_now
      expect(ActionMailer::Base.deliveries.count).to eq(1)
    end

    it 'should send to the receiver email address' do
      approval = create(:approval)
      approval_array = Approval.where(id: approval.id)
      role = create(:role, id: 2)
      admin = create(:user, role_id: role.id, email: 'faridul.ahmad@tinkerbox.com.sg')
      ApprovalPendingMailer.reminder(approval_array, admin).deliver_now
      expect(ActionMailer::Base.deliveries.first.to.first).to eq('faridul.ahmad@tinkerbox.com.sg')
    end

    it 'should set the subject to the correct subject' do
      approval = create(:approval)
      approval_array = Approval.where(id: approval.id)
      role = create(:role, id: 2)
      admin = create(:user, role_id: role.id, email: 'faridul.ahmad@tinkerbox.com.sg')
      ApprovalPendingMailer.reminder(approval_array, admin).deliver_now
      expect(ActionMailer::Base.deliveries.first.subject).to eq('Insurance Market API Portal: Pending Approval Reminder')
    end

  end

end
