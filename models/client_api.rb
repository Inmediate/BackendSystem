class ClientApi < ApplicationRecord
  validates :path, presence: true
  validates :path, uniqueness: true, if: :api_active?

  belongs_to :product
  has_many :insurer_product_apis
  has_many :client_api_clients, dependent: :destroy
  has_many :clients, through: :client_api_clients

  after_create :update_path
  after_update :update_path
  after_update :delete_insurer_api, if: :deleted?
  after_update :delete_associate, if: :deleted?

  audited

  def get_payloads
    payload = self.payloads
    if payload.nil?
      @payload = []
    else
      if JSON.parse(self.payloads).any?
        @payload = JSON.parse(self.payloads)
      else
        @payload = []
      end
    end
      @payload
  end

  private

  def end_point
    "#{method}#{path}"
  end

  def api_active?
    status
  end

  def deleted?
    !status
  end

  def redis
    $redis
  end

  def update_path

    #get all avalilable path
    path_update = []
    ClientApi.where(status: true).where(activation_status: true).each do |api|
      path_update << "#{api.method}/#{api.path}"
      path_update << api.id
    end

    # delete prevoius path
    redis.flushall

    # update new path
    redis.mset(path_update)

  end

  def delete_insurer_api

    InsurerProductApi.where(status: true).where(client_api_id: self.id).each do |insurer_api|
      object_id = insurer_api.id
      insurer_api.update(status: false)
      puts "Destroy Insurer Product API: #{object_id}"
    end

    Approval.where(table: 'INSURER_PRODUCT_API').each do |approval|
      next if approval.content.blank?
      next unless JSON.parse(approval.content)['client_api_id'] == self.id.to_s
      object_id = approval.id
      approval.destroy
      puts "Destroy Approval's Insurer Product API: #{object_id}"
    end

  end

  def delete_associate
    ClientApiClient.where(client_api_id: self.id).destroy_all
    puts "Destroy client client_api associate"
  end


end
