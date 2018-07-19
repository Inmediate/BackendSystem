class Approval < ApplicationRecord
  audited on: %i[create update]

  after_create :email_create
  after_update :email_update

  def parse_content
    JSON.parse(content)
  end

  def client_api_product
    product = ''
    unless content.blank?
      product = Product.find(JSON.parse(content)['product_id']).name
    end
    product
  end

  def mapping_count_list
    count_list = ''
    count_list = JSON.parse(content)['list'].split("\n").count unless content.blank?
    count_list
  end

  def insurer_supported_product
    list = ''
    JSON.parse(JSON.parse(content)['products']).each do |product|
      list << "#{Product.find(product).code}\n"
    end
    list
  end

  def insurer_product_api_client_api
    client_api_name = ''
    client_api_id = nil
    unless content.blank?
      client_api_id = JSON.parse(content)['client_api_id'].to_i
    end
    unless ClientApi.where(id: client_api_id).blank?
      client_api_name = ClientApi.find(client_api_id).name
    end
    client_api_name
  end

  def insurer_product_api_is_authetication
    is_authentication = false
    is_authentication = true if JSON.parse(content)['is_authentication'] == '1'
  end

  # def approve_create(editor, status, model)
  #

  # def approve_update(editor, status, model, content)
  #   users = User.where(role_id: 1..2).where(status: true).where(activation_status: true)
  #   users.each do |user|
  #     ApprovalMailer.delay.approve_update(self, user, status, editor, model, content)
  #   end
  # end

  private

  def email_create
    users = User.where(role_id: 1..2).where(status: true).where(activation_status: true)
    users.each do |user|
      ApprovalMailer.delay.create(self, user)
    end
  end

  def email_update
    users = User.where(role_id: 1..2).where(status: true).where(activation_status: true)
    users.each do |user|
      ApprovalMailer.delay.update(self, user)
    end
  end


end

