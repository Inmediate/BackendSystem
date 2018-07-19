class ClientApiClient < ApplicationRecord
  belongs_to :client_api
  belongs_to :client
end
