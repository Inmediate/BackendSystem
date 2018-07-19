class InsurerProduct < ApplicationRecord
  belongs_to :insurer
  belongs_to :product
end
