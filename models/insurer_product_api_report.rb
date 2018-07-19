class InsurerProductApiReport < ApplicationRecord
end

class InsurerApiLogFilter
  include Minidusen::Filter

  filter :text do |scope, phrases|
    columns = [:insurer_product_api_id, :source, :request_url, :request_id, :response_code, :request_method]
    scope.where_like(columns => phrases)
  end
end
