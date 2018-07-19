class ApprovalPendingMailer < ApplicationMailer
  def reminder(approvals, receiver)
    return if approvals.nil?
    return if receiver.nil?
    @approvals = approvals
    @receiver = receiver
    mail(to: @receiver.email, subject: 'Insurance Market API Portal: Pending Approval Reminder')
  end
end
