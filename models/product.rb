class Product < ApplicationRecord
  validates :name, presence: true
  validates :code, presence: true
  validates :code, uniqueness: true, if: :not_deleted?
  has_many :client_apis, dependent: :destroy
  has_many :insurer_products, dependent: :destroy
  has_many :insurers, through: :insurer_products

  after_update :deactivate_client_api, if: :deactivated?
  after_update :delete_client_api, if: :deleted?

  #delete insurer client table
  after_update :delete_insurer_client, if: :deactivated?
  after_update :delete_insurer_client, if: :deleted?

  audited

  private

  def not_deleted?
    self.status
  end

  def deactivated?
    !self.activation_status
  end

  def deleted?
    !self.status
  end

  def deactivate_client_api

    ClientApi.where(product: self.id).where(status: true).each do |api|
      api.update(activation_status: false)
    end

  end

  def delete_client_api

    ClientApi.where(product: self.id).where(status: true).each do |api|
      object_id = api.id
      api.update(status: false)
      puts "Delete Client API: #{object_id}"
    end

    Approval.where(table: 'CLIENT_API').each do |approval|
      puts "start delete approval client api"
      content = JSON.parse(approval.content)
      next unless content['product_id'] == self.id.to_s
      object_id = approval.id
      approval.destroy
      puts "Delete Approval: #{object_id}"

    end

    InsurerProduct.where(product_id: self.id).each do |insurer_product|
      object_id = insurer_product.id
      insurer_product.destroy
      puts "Delete insurer_product: #{object_id}"
    end

  end

  def delete_insurer_client
    InsurerClient.where(product_id: self.id).each do |insurer_client|
      object_id = insurer_client.id
      insurer_client.destroy
      puts "Delete insurer_client: #{object_id}"
    end
  end

end
