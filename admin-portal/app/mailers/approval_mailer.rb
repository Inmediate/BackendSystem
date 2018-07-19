class ApprovalMailer < ApplicationMailer

  def create(approval, user)
    return if approval.nil?
    return if user.nil?
    @approval = approval
    @user = user
    @editor = User.find(@approval.user).name
    @action = @approval.row_id.blank? ? 'created' : 'updated'
    @model = @approval.table.tr('_', ' ').split.map(&:capitalize).join(' ')
    @content = ''
    if @action == 'updated'
      if @approval.table == 'INSURER'
        @content = "- #{JSON.parse(@approval.content)['company_name']}"
      elsif @approval.table == 'INSURER_PRODUCT_API'
        @content = "- #{JSON.parse(@approval.content)['api_method']} #{JSON.parse(@approval.content)['api_url']}"
      else
        @content = "- #{JSON.parse(@approval.content)['name']}"
      end
    end
    mail(to: @user.email, subject: 'Insurance Market API Portal: Approval Created')
  end

  def update(approval, user)
    return if approval.nil?
    return if user.nil?
    @approval = approval
    @user = user
    @editor = User.find(@approval.user).name
    @model = @approval.table.tr('_', ' ').split.map(&:capitalize).join(' ')
    @content = "- #{JSON.parse(@approval.content)['name']}"
    if @approval.table == 'INSURER'
      @content = "- #{JSON.parse(@approval.content)['company_name']}"
    elsif @approval.table == 'INSURER_PRODUCT_API'
      @content = "- #{JSON.parse(@approval.content)['api_method']} #{JSON.parse(@approval.content)['api_url']}"
    end
    mail(to: @user.email, subject: 'Insurance Market API Portal: Approval Updated')

  end

  def approve_create(user, status, editor, model)
    return if user.nil?
    @user = user
    @status = status
    @editor = editor
    @model = model
    mail(to: @user.email, subject: "Insurance Market API Portal: Content #{@status == 'approved' ? "Approved" : "Rejected"}")
  end

  def approve_update(user, status, editor, model, content)
    return if user.nil?
    @user = user
    @status = status
    @editor = editor
    @model = model
    @content = content
    mail(to: @user.email, subject: "Insurance Market API Portal: Content #{@status == 'approved' ? "Approved" : "Rejected"}")
  end


end
