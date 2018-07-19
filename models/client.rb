class Client < ApplicationRecord
  include ActiveModel::Dirty
  validates :name, presence: true
  validates :contact_person_name, presence: true
  validates :contact_person_email, presence: true
  has_many :client_api_clients, dependent: :destroy
  has_many :client_apis, through: :client_api_clients
  has_many :insurer_clients, dependent: :destroy
  has_many :insurers, through: :insurer_clients

  after_create :client_created
  after_update :client_deactivated, if: :deactivated?
  after_update :client_deleted, if: :deleted?


  audited

  def generate_client_code
    client_code = SecureRandom.random_number(1_000_000_000_000)
    generate_client_code if Client.exists?(client_code: client_code)
    client_code
  end

  def generate_client_code_save
    self.client_code = SecureRandom.random_number(1_000_000_000_000)
    generate_client_code_save if Client.exists?(client_code: client_code)
    save
  end

  def generate_client_api_key
    client_api_key = SecureRandom.hex(24)
    generate_client_api_key if Client.exists?(client_api_key: client_api_key)
    client_api_key
  end

  def generate_client_api_key_save
    self.client_api_key = SecureRandom.hex(24)
    generate_client_api_key_save if Client.exists?(client_api_key: client_api_key)
    save
  end


  private

  def deactivated?
    activation_status_changed? && !self.activation_status
  end

  def deleted?
    !status
  end

  def client_created
    ClientMailer.delay.create(self)
  end

  def client_deactivated
    ClientMailer.delay.deactivated(self)
  end

  def client_deleted
    # send email
    ClientMailer.delay.deleted(self)

    #delete association with client api
    ClientApiClient.where(client_id: self.id).each do |client_api_client|
      object_id = client_api_client.id
      client_api_client.destroy
      puts "Destroy client_api_client: #{object_id}"
    end

    #delete association with Insurer
    InsurerClient.where(client_id: self.id).each do |insurer_client|
      object_id = insurer_client.id
      insurer_client.destroy
      puts "Destroy client_api_client: #{object_id}"
    end


  end


end
