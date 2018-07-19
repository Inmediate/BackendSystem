class ClientApiReport < ApplicationRecord
end
class ClientApiLogFilter
  include Minidusen::Filter

  filter :text do |scope, phrases|
    columns = [:client_id, :client_api_key, :client_api_id, :request_ip, :request_endpoint, :request_method, :response_code]
    scope.where_like(columns => phrases)
  end
end
