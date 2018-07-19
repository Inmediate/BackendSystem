class Insurer < ApplicationRecord

  validates :company_code, presence: true
  validates :company_code, uniqueness: true, if: :insurer_active?

  has_many :insurer_product_apis, dependent: :destroy
  has_many :insurer_products, dependent: :destroy
  has_many :products, through: :insurer_products
  has_many :insurer_clients, dependent: :destroy
  has_many :clients, through: :insurer_clients

  after_create :send_email # commented to run rspec in cron job application or client api application
  after_update :insurer_deleted, if: :deleted?

  audited

  def supported_products
    list = ''
    products.each_with_index do |product, index|
      list << "#{product.code} "
    end
    list
  end

  def delete_clone_mapping(map_id)

    # delete mapping at insurer
    mapping_index = nil
    unless self.mapping.blank?
      mapping_head = JSON.parse(self.mapping)
      mapping_head.each_with_index do |map, index|
        if map_id.to_s == map.first
          mapping_index = index
        end
      end

      mapping_head.delete_at(mapping_index)
      self.mapping = mapping_head.to_json
      save
    end

    # delete mapping at insurer product api
    unless self.insurer_product_apis.blank?
      self.insurer_product_apis.each do |api|

      end
    end

  end

  def api_list
    list = ''
    InsurerProductApi.where(insurer_id: id).where(status: true).where(activation_status: true).each do |api|
      list << "#{api.api_method} #{api.api_url} \n"
    end
    list
  end


  private

  def send_email
    InsurerMailer.delay.create(self)
  end

  def insurer_active?
    status
  end

  def deleted?
    !status
  end

  def insurer_deleted

    #delete insurer product apis
    self.insurer_product_apis.where(status: true).each do |api|
      object_id = api.id
      api.update(status: false)
      puts "Destroy Insurer Product API: #{object_id}"
    end

    #destroy approval
    Approval.where(table: 'INSURER_PRODUCT_API').each do |approval|
      next if approval.content.blank?
      next if JSON.parse(approval.content).blank?
      next unless JSON.parse(approval.content)['insurer_id'] == self.id.to_s
      object_id = approval.id
      approval.destroy
      puts "Destroy Approval's Insurer Product API: #{object_id}"
    end

    #destroy insurer-product associations
    InsurerProduct.where(insurer_id: self.id).each do |insurer_product|
      object_id = insurer_product.id
      insurer_product.destroy
      puts "Destroy Insurer Product: #{object_id}"
    end

  end


end
