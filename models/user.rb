class User < ApplicationRecord
  belongs_to :role
  has_many :sessions
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  audited except: :password_hash

  # users.password_hash in the database is a :string
  include BCrypt

  def password
    @password ||= Password.new(password_hash)
  end

  def password=(new_password)
    @password = Password.create(new_password)
    self.password_hash = @password
  end

  def reset_password
    self.reset_password_token = SecureRandom.hex(12)
    self.reset_password_send_at = Time.now
    reset_password if User.exists?(reset_password_token: reset_password_token)
    save
  end

  def invitation
    self.invitation_token = SecureRandom.hex(12)
    self.invitation_send_at = Time.now
    invitation if User.exists?(invitation_token: invitation_token)
    save
  end

  # def api_active?
  #   status
  # end

end
