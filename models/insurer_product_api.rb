class InsurerProductApi < ApplicationRecord

  validates :api_method, presence: true
  validates :api_url, presence: true
  # validates :api_url, uniqueness: true, if: :api_active?
  belongs_to :client_api, required: false
  belongs_to :insurer

  after_update :trim_url
  after_create :trim_url

  audited

  def selection_name
    "#{api_method} #{api_url}"
  end

  def api_active?
    status
  end

  private

  def trim_url
    url = api_url.gsub(/\s+/, '')
    update_column(:api_url, url)
  end

end
class InsurerProductAPIFilter
  include Minidusen::Filter

  filter :text do |scope, phrases|
    columns = [:cache_policy, :api_url, :api_method, :api_flavour, :payload_type, 'client_apis.name']
    scope.joins('left join client_apis on client_apis.id = client_api_id').where_like(columns => phrases)
  end
end