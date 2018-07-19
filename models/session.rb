class Session < ApplicationRecord
  belongs_to :user
end
class SessionLogFilter
  include Minidusen::Filter

  filter :text do |scope, phrases|
    columns = [:user_id, :ip_address, :platform, :browser, 'users.name']
    scope.joins('left join users on users.id = user_id').where_like(columns => phrases)
  end
end