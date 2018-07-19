class InsurerClient < ApplicationRecord
  belongs_to :insurer
  belongs_to :client
end
