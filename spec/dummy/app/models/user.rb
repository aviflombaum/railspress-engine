class User < ApplicationRecord
  validates :email_address, presence: true
end
